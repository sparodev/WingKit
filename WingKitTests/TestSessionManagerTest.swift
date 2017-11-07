//
//  TestSessionManagerTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 11/2/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class TestSessionManagerTest: WingKitTestCase {

    var testSession: TestSession!
    var testObject: TestSessionManager!
    
    override func setUp() {
        super.setUp()

        testSession = createTestSession()
        testObject = TestSessionManager(testSession: testSession)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        XCTAssertNotNil(testObject)
        XCTAssertEqual(testObject.testSession.id, testSession.id)
    }

    func testProcessTestSessionSendsNetworkRequest() {

        Client.token = "randomToken"

        mockNetwork.sendRequestStub = { request, completion in

            if let networkRequest = request as? NetworkRequest {

                let expectedEndpoint = TestSessionEndpoint.retrieve(sessionId: self.testSession.id)
                XCTAssertEqual(networkRequest.url.absoluteString, Client.baseURLPath + expectedEndpoint.path)
                XCTAssertEqual(networkRequest.method, expectedEndpoint.method)
            }

            completion(self.testSessionJSON(), nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if error != nil {
                XCTFail()
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProcessTestSessionWhenRefershTimeoutOccurs() {

        Client.token = "token"

        var json = testSessionJSON()

        json[TestSession.Keys.tests] = [
            [
                Test.Keys.id: "testid1",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId1"
            ],
            [
                Test.Keys.id: "testid2",
                Test.Keys.breathDuration: 6134.0,
                Test.Keys.pef: 3515.0,
                Test.Keys.fev1: 3518.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-8908).iso8601,
                Test.Keys.status: TestStatus.processing.rawValue,
                Test.Keys.totalVolume: 5173.0,
                Test.Keys.upload: "uploadId2"
            ],
        ]

        let decoder = WingKit.JSONDecoder()
        let testSession = try! decoder.decode(TestSession.self, from: json)
        testObject = TestSessionManager(testSession: testSession)

        let callbackExpectation = expectation(description: "wait for callback")
        var retrieveTestSessionAttempts = 0
        let expectedTestSessionAttempts = 10

        mockNetwork.sendRequestStub = { request, completion in

            if let networkRequest = request as? NetworkRequest {

                let expectedEndpoint = TestSessionEndpoint.retrieve(sessionId: self.testSession.id)
                XCTAssertEqual(networkRequest.url.absoluteString, Client.baseURLPath + expectedEndpoint.path)
                XCTAssertEqual(networkRequest.method, expectedEndpoint.method)

                retrieveTestSessionAttempts += 1
            }

            completion(json, nil)
        }

        testObject.processTestSession { (error) in

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case TestSessionManagerError.processingTimeout:

                callbackExpectation.fulfill()

            default: XCTFail()
            }
        }

        waitForExpectations(timeout: Double(expectedTestSessionAttempts), handler: nil)

        XCTAssertEqual(retrieveTestSessionAttempts, expectedTestSessionAttempts)
    }

    func testProcessTestSessionUpdatesStateWhenFirstTestIsSuccessful() {

    }

    func testProcessTestSessionUpdatesStateWhenFirstTestIsUnprocessible() {

    }

    func testProcessTestSessionUpdatesStateWhenFirstTwoTestsAreNotReproducible() {

    }

    func testProcessTestSessionUpdatesStateWhenFirstTwoTestsAreReproducible() {

    }

    func testProcessTestSessionUpdatesStateWhenResultsFromThreeTestsAreNotReproducible() {

    }

    func testProcessTestSessionUpdatesStateWhenResultsFromThreeTestsAreReproducible() {

    }



    // MARK: - Helper Methods

    func testSessionJSON() -> JSON {
        return [
            TestSession.Keys.id: "testId",
            TestSession.Keys.startedAt: Date().addingTimeInterval(-8000).iso8601,
            TestSession.Keys.endedAt: Date().iso8601,
            TestSession.Keys.lungFunctionZone: LungFunctionZone.greenZone.rawValue,
            TestSession.Keys.respiratoryState: RespiratoryState.greenZone.rawValue,
            TestSession.Keys.bestTest: [
                Test.Keys.id: "testid1",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.exhaleCurve: [],
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId1"
            ],
            TestSession.Keys.tests: [
                [
                    Test.Keys.id: "testid1",
                    Test.Keys.breathDuration: 1234.0,
                    Test.Keys.pef: 2345.0,
                    Test.Keys.fev1: 3456.0,
                    Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                    Test.Keys.status: TestStatus.complete.rawValue,
                    Test.Keys.totalVolume: 5614.0,
                    Test.Keys.upload: "uploadId1"
                ],
                [
                    Test.Keys.id: "testid2",
                    Test.Keys.breathDuration: 6134.0,
                    Test.Keys.pef: 3515.0,
                    Test.Keys.fev1: 3518.0,
                    Test.Keys.takenAt: Date().addingTimeInterval(-8908).iso8601,
                    Test.Keys.status: TestStatus.complete.rawValue,
                    Test.Keys.totalVolume: 5173.0,
                    Test.Keys.upload: "uploadId2"
                ],
            ],
            TestSession.Keys.uploads: [
                [
                    UploadTarget.Keys.id: "uploadId1",
                    UploadTarget.Keys.key: "uploadKey1",
                    UploadTarget.Keys.bucket: "uploadBucket1"
                ],
                [
                    UploadTarget.Keys.id: "uploadId2",
                    UploadTarget.Keys.key: "uploadKey2",
                    UploadTarget.Keys.bucket: "uploadBucket2"
                ]
            ]
        ]
    }

    func createTestSession() -> TestSession {
        let decoder = WingKit.JSONDecoder()
        return try! decoder.decode(TestSession.self, from: testSessionJSON())
    }
}
