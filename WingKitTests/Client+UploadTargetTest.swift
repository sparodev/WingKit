//
//  Client+UploadTargetTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/27/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class Client_UploadTargetTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateUploadTargetWhenSuccessful() {

        let sessionId = UUID().uuidString

        let expectedTargetId = UUID().uuidString
        let expectedTargetKey = "target-key"
        let expectedTargetBucket = "target-bucket"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            do {
                let urlRequest = try request.asURLRequest()

                XCTAssertEqual(urlRequest.url?.absoluteString,
                               Client.baseURLPath + UploadTargetEndpoint.create(sessionId: sessionId).path)
                XCTAssertEqual(urlRequest.httpMethod,
                               UploadTargetEndpoint.create(sessionId: sessionId).method.rawValue)
            } catch {
                XCTFail()
            }

            completion([
                UploadTarget.Keys.id: expectedTargetId,
                UploadTarget.Keys.key: expectedTargetKey,
                UploadTarget.Keys.bucket: expectedTargetBucket
                ], nil)

            sendRequestExpectation.fulfill()
        }

        Client.createUploadTarget(forTestSessionId: sessionId) { target, error in

            guard let target = target else {
                XCTFail()
                return
            }

            XCTAssertEqual(target.id, expectedTargetId)
            XCTAssertEqual(target.key, expectedTargetKey)
            XCTAssertEqual(target.bucket, expectedTargetBucket)

            completionCallbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenDecodingFails() {

        let sessionId = UUID().uuidString

        let expectedTargetKey = "target-key"
        let expectedTargetBucket = "target-bucket"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion([
                UploadTarget.Keys.key: expectedTargetKey,
                UploadTarget.Keys.bucket: expectedTargetBucket
                ], nil)

            sendRequestExpectation.fulfill()
        }

        Client.createUploadTarget(forTestSessionId: sessionId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case WingKit.DecodingError.decodingFailed: completionCallbackExpectation.fulfill()
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenResponseIsInvalid() {

        let sessionId = UUID().uuidString

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, nil)

            sendRequestExpectation.fulfill()
        }

        Client.createUploadTarget(forTestSessionId: sessionId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case NetworkError.invalidResponse: completionCallbackExpectation.fulfill()
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenServerRespondsWithError() {

        let sessionId = UUID().uuidString
        let expectedStatusCode = 400

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, NetworkError.unacceptableStatusCode(code: expectedStatusCode))

            sendRequestExpectation.fulfill()
        }

        Client.createUploadTarget(forTestSessionId: sessionId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case NetworkError.unacceptableStatusCode(let code):
                if code == expectedStatusCode {
                    completionCallbackExpectation.fulfill()
                } else {
                    XCTFail("Received unexpected status code: \(code)")
                }
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
