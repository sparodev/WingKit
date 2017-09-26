//
//  UploadTargetTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/26/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class UploadTargetTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitWithDecoderWhenJSONIsValid() {

        let expectedId = UUID().uuidString
        let expectedKey = "test-key"
        let expectedBucket = "test-bucket"

        let json = [
            UploadTarget.Keys.id: expectedId,
            UploadTarget.Keys.key: expectedKey,
            UploadTarget.Keys.bucket: expectedBucket
        ]

        let decoder = WingKit.JSONDecoder()
        do {
            let target = try decoder.decode(UploadTarget.self, from: json)

            XCTAssertEqual(target.id, expectedId)
            XCTAssertEqual(target.key, expectedKey)
            XCTAssertEqual(target.bucket, expectedBucket)

        } catch {
            XCTFail()
        }
    }

    func testInitWithDecoderWhenJSONIsInvalid() {

        let expectedKey = "test-key"
        let expectedBucket = "test-bucket"

        let json = [
            UploadTarget.Keys.key: expectedKey,
            UploadTarget.Keys.bucket: expectedBucket
        ]

        let errorCallbackExpectation = expectation(description: "wait for error")

        let decoder = WingKit.JSONDecoder()
        do {
            _ = try decoder.decode(UploadTarget.self, from: json)
        } catch WingKit.DecodingError.decodingFailed {
            errorCallbackExpectation.fulfill()
        } catch {
            XCTFail()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testInitWithDecoderWhenJSONIsNil() {

        let decoder = WingKit.JSONDecoder()
        let target = UploadTarget(from: decoder)

        XCTAssertNil(target)
    }
}
