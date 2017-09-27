//
//  TestTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/22/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

extension Test {

    static func sampleJSON() -> JSON {
        return [
            Test.Keys.id: UUID().uuidString,
            Test.Keys.takenAt: Date().iso8601,
            Test.Keys.status: Test.Status.processing.string,
            Test.Keys.breathDuration: 7.0,
            Test.Keys.exhaleCurve: [
                [1.0, 2.0],
                [3.0, 4.0]
            ],
            Test.Keys.totalVolume: 6.0,
            Test.Keys.pef: 5.0,
            Test.Keys.fev1: 4.0
        ]
    }
}

class TestTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTestStatusStringValues() {
        XCTAssertEqual(Test.Status.started.string, "Started")
        XCTAssertEqual(Test.Status.complete.string, "Complete")
        XCTAssertEqual(Test.Status.uploaded.string, "Uploaded")
        XCTAssertEqual(Test.Status.processing.string, "Processing")
        XCTAssertEqual(Test.Status.error.string, "Error")
    }

    func testTestStatusStringToEnum() {

        XCTAssertEqual(Test.Status.stringToEnum("Started"), Test.Status.started)
        XCTAssertEqual(Test.Status.stringToEnum("Complete"), Test.Status.complete)
        XCTAssertEqual(Test.Status.stringToEnum("Uploaded"), Test.Status.uploaded)
        XCTAssertEqual(Test.Status.stringToEnum("Processing"), Test.Status.processing)
        XCTAssertEqual(Test.Status.stringToEnum("Error"), Test.Status.error)
        XCTAssertEqual(Test.Status.stringToEnum("Targaryen"), nil)
    }

    func testIsDecodableFromJSON() {

        let expectedId = UUID().uuidString
        let expectedTakenAt = Date()
        let expectedStatus = Test.Status.processing
        let expectedBreathDuration = 7.0
        let expectedExhaleCurve = [
            [1.0, 2.0],
            [3.0, 4.0]
        ]
        let expectedTotalVolume = 6.0
        let expectedPEF = 5.0
        let expectedFEV1 = 4.0
        let expectedUploadTargetId = UUID().uuidString

        let json: JSON = [
            Test.Keys.id: expectedId,
            Test.Keys.takenAt: expectedTakenAt.iso8601,
            Test.Keys.status: expectedStatus.string,
            Test.Keys.breathDuration: expectedBreathDuration,
            Test.Keys.exhaleCurve: expectedExhaleCurve,
            Test.Keys.totalVolume: expectedTotalVolume,
            Test.Keys.pef: expectedPEF,
            Test.Keys.fev1: expectedFEV1,
            Test.Keys.upload: expectedUploadTargetId
        ]

        let decoder = WingKit.JSONDecoder()

        var test: Test?
        do {
            test = try decoder.decode(Test.self, from: json)
        } catch {
            XCTFail()
        }

        guard let testObject = test else {
            XCTFail()
            return
        }

        XCTAssertEqual(testObject.id, expectedId)
        XCTAssertEqual(testObject.takenAt!.timeIntervalSinceReferenceDate,
                       expectedTakenAt.timeIntervalSinceReferenceDate, accuracy: 0.02)
        XCTAssertEqual(testObject.status, expectedStatus)
        XCTAssertEqual(testObject.breathDuration, expectedBreathDuration)

        for (index, point) in testObject.exhaleCurve.enumerated() {
            XCTAssertEqual(point[0], expectedExhaleCurve[index][0])
            XCTAssertEqual(point[1], expectedExhaleCurve[index][1])
        }

        XCTAssertEqual(testObject.totalVolume, expectedTotalVolume)
        XCTAssertEqual(testObject.pef, expectedPEF)
        XCTAssertEqual(testObject.fev1, expectedFEV1)
        XCTAssertEqual(testObject.uploadTargetId, expectedUploadTargetId)
    }

    func testFailsDecodingWhenIdIsNil() {

        let expectedTakenAt = Date()
        let expectedStatus = Test.Status.processing
        let expectedBreathDuration = 7.0
        let expectedExhaleCurve = [
            [1.0, 2.0],
            [3.0, 4.0]
        ]
        let expectedTotalVolume = 6.0
        let expectedPEF = 5.0
        let expectedFEV1 = 4.0

        let json: JSON = [
            Test.Keys.takenAt: expectedTakenAt.iso8601,
            Test.Keys.status: expectedStatus.string,
            Test.Keys.breathDuration: expectedBreathDuration,
            Test.Keys.exhaleCurve: expectedExhaleCurve,
            Test.Keys.totalVolume: expectedTotalVolume,
            Test.Keys.pef: expectedPEF,
            Test.Keys.fev1: expectedFEV1
        ]

        let errorExpectation = expectation(description: "Wait for error callback")

        let decoder = WingKit.JSONDecoder()

        var testObject: Test?
        do {
            testObject = try decoder.decode(Test.self, from: json)
        } catch WingKit.DecodingError.decodingFailed {
            errorExpectation.fulfill()
        } catch {
            XCTFail("Caught an unexpected error: \(error)")
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertNil(testObject)
    }
}
