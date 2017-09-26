//
//  Client+TestSessionTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class Client_TestSessionTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTestSessionEndpointPaths() {

        XCTAssertEqual(TestSessionEndpoint.create.path, "/test-sessions")
        XCTAssertEqual(TestSessionEndpoint.retrieve(sessionId: "test-id").path, "/test-sessions/test-id")
        XCTAssertEqual(TestSessionEndpoint.update(sessionId: "test-id").path, "/test-sessions/test-id")
    }

    func testTestSessionEndpointMethods() {

        XCTAssertEqual(TestSessionEndpoint.create.method, .post)
        XCTAssertEqual(TestSessionEndpoint.retrieve(sessionId: "test-id").method, .get)
        XCTAssertEqual(TestSessionEndpoint.update(sessionId: "test-id").method, .put)
    }

    func testCreateTestSessionWhenSuccessful() {

        let expectedTestSessionId = UUID().uuidString
        let expectedStartedAt = Date()

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            do {
                let urlRequest = try request.asURLRequest()

                XCTAssertEqual(urlRequest.url?.absoluteString, Client.baseURLPath + TestSessionEndpoint.create.path)
                XCTAssertEqual(urlRequest.httpMethod, TestSessionEndpoint.create.method.rawValue)
            } catch {
                XCTFail()
            }

            completion([
                TestSession.Keys.id: expectedTestSessionId,
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        Client.createTestSession { (testSession, error) in

            guard let testSession = testSession else {
                XCTFail()
                return
            }

            XCTAssertEqual(testSession.id, expectedTestSessionId)
            XCTAssertEqual(testSession.startedAt.timeIntervalSinceReferenceDate,
                           expectedStartedAt.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)

            XCTAssertEqual(testSession.uploadTargets.count, 2)
            XCTAssertEqual(testSession.uploadTargets[0].id, expectedUploadId1)
            XCTAssertEqual(testSession.uploadTargets[0].key, expectedUploadKey1)
            XCTAssertEqual(testSession.uploadTargets[0].bucket, expectedUploadBucket)
            XCTAssertEqual(testSession.uploadTargets[1].id, expectedUploadId2)
            XCTAssertEqual(testSession.uploadTargets[1].key, expectedUploadKey2)
            XCTAssertEqual(testSession.uploadTargets[1].bucket, expectedUploadBucket)

            completionCallbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateTestSessionWhenDecoidngFails() {

        let expectedStartedAt = Date()

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion([
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        Client.createTestSession { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testCreateTestSessionWhenResponseIsInvalid() {

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, nil)

            sendRequestExpectation.fulfill()
        }


        Client.createTestSession { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testCreateTestSessionWhenServerRespondsWithError() {

        let expectedStatusCode = 400
        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, NetworkError.unacceptableStatusCode(code: expectedStatusCode))

            sendRequestExpectation.fulfill()
        }


        Client.createTestSession { (testSession, error) in

            XCTAssertNil(testSession)

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
