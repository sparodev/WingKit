//
//  ClientTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class ClientTest: WingKitTestCase {

    var testObject: Client!
    
    override func setUp() {
        super.setUp()

        testObject = Client()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOAuthCredentialsInit() {
        let expectedId = UUID().uuidString
        let expectedSecret = UUID().uuidString

        let testObject = OAuthCredentials(id: expectedId, secret: expectedSecret)

        XCTAssertEqual(testObject.id, expectedId)
        XCTAssertEqual(testObject.secret, expectedSecret)
    }

    func testAuthenticationEndpointPath() {
        XCTAssertEqual(AuthenticationEndpoint.authenticate.path, "/accounts/login")
    }

    func testAuthenticationEndpointMethod() {
        XCTAssertEqual(AuthenticationEndpoint.authenticate.method, .post)
    }

    func testAuthenticationEndpointAcceptableStatusCodes() {
        XCTAssertEqual(AuthenticationEndpoint.authenticate.acceptableStatusCodes, [200])
    }
    
    func testRequestCreationWithValidURL() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }

            var acceptableStatusCodes: [Int] {
                return [200]
            }
        }

        var request: NetworkRequest?
        do {
            request = try testObject.request(for: TestEndpoint.test)
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        XCTAssertEqual(createdRequest.url.absoluteString, testObject.baseURLPath + TestEndpoint.test.path)
        XCTAssertEqual(createdRequest.method, TestEndpoint.test.method)
        XCTAssertEqual(createdRequest.acceptableStatusCodes.count, 1)
        XCTAssertEqual(createdRequest.acceptableStatusCodes.first, 200)
    }

    func testRequestCreationWithInvalidURL() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return ":?1/%^!invalidPath"
            }

            var acceptableStatusCodes: [Int] {
                return [200]
            }
        }

        let errorExpectation = expectation(description: "wait for error")

        var request: NetworkRequest?
        do {
            request = try testObject.request(for: TestEndpoint.test)
        } catch ClientError.invalidURL {
            errorExpectation.fulfill()
        } catch {
            XCTFail("Caught unexpected error: \(error)")
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertNil(request)
    }

    func testRequestCreationPopulatesDefaultHeaders() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }

            var acceptableStatusCodes: [Int] {
                return [200]
            }
        }

        var request: NetworkRequest?
        do {
            request = try testObject.request(for: TestEndpoint.test)
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let headers = createdRequest.headers else {
            XCTFail()
            return
        }

        guard let acceptValue = headers["Accept"] else {
            XCTFail("Could not find Accept header value!")
            return
        }

        guard let contentTypeValue = headers["Content-Type"] else {
            XCTFail("Could not find Content-Type header value!")
            return
        }

        XCTAssertEqual(acceptValue, "application/json")
        XCTAssertEqual(contentTypeValue, "application/json")
    }

    func testRequestCreationPopulatesCustomHeaders() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }

            var acceptableStatusCodes: [Int] {
                return [200]
            }
        }

        let expectedAcceptValue = "something different"
        let expectedContentType = "a different type"
        let expectedCustomHeaderKey = "different key"
        let expectedCustomHeaderValue = "custom value"

        var request: NetworkRequest?
        do {
            request = try testObject.request(
                for: TestEndpoint.test,
                headers: [
                    "Accept": expectedAcceptValue,
                    "Content-Type": expectedContentType,
                    expectedCustomHeaderKey: expectedCustomHeaderValue
                    ]
            )
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let headers = createdRequest.headers else {
            XCTFail()
            return
        }

        guard let acceptValue = headers["Accept"] else {
            XCTFail("Could not find Accept header value!")
            return
        }

        guard let contentTypeValue = headers["Content-Type"] else {
            XCTFail("Could not find Content-Type header value!")
            return
        }

        guard let customValue = headers[expectedCustomHeaderKey] else {
            XCTFail("Could not find custom key in headers")
            return
        }

        XCTAssertEqual(acceptValue, expectedAcceptValue)
        XCTAssertEqual(contentTypeValue, expectedContentType)
        XCTAssertEqual(customValue, expectedCustomHeaderValue)
    }

    func testRequestCreationPopulatesParameters() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }

            var acceptableStatusCodes: [Int] {
                return [200]
            }
        }

        let intValueKey = "intValueKey"
        let expectedIntValue = 8

        let stringValueKey = "stringValueKey"
        let expectedStringValue = "something goes here"

        var request: NetworkRequest?
        do {
            request = try testObject.request(
                for: TestEndpoint.test,
                parameters: [
                    intValueKey: expectedIntValue,
                    stringValueKey: expectedStringValue
                ])
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let parameters = createdRequest.parameters else {
            XCTFail()
            return
        }

        guard let intValue = parameters[intValueKey] as? Int else {
            XCTFail("Could not find intValueKey value!")
            return
        }

        guard let stringValue = parameters[stringValueKey] as? String else {
            XCTFail("Could not find stringValueKey value!")
            return
        }

        XCTAssertEqual(intValue, expectedIntValue)
        XCTAssertEqual(stringValue, expectedStringValue)
    }

    func testAuthenticateReturnsTokenFromResponse() {

        let expectedToken = UUID().uuidString
        let expectedClientID = UUID().uuidString
        let expectedClientSecret = UUID().uuidString

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail("Found unexpected request: \(request)")
                return
            }

            XCTAssertEqual(networkRequest.parameters![OAuthParameterKeys.id] as! String, expectedClientID)
            XCTAssertEqual(networkRequest.parameters![OAuthParameterKeys.secret] as! String, expectedClientSecret)
            XCTAssertEqual(networkRequest.url.absoluteString,
                           self.testObject.baseURLPath + AuthenticationEndpoint.authenticate.path)

            completion(["token": expectedToken], nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.oauth = OAuthCredentials(id: expectedClientID, secret: expectedClientSecret)

        testObject.authenticate { (token, error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            guard let token = token else {
                XCTFail("Expected to find a valid token.")
                return
            }

            XCTAssertEqual(token, expectedToken)

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAuthenticateWhenNoTokenFoundInResponse() {

        mockNetwork.sendRequestStub = { request, completion in
            completion([:], nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.oauth = OAuthCredentials(id: UUID().uuidString, secret: UUID().uuidString)

        testObject.authenticate { (token, error) in

            guard let error = error else {
                XCTFail("Expected to catch an error.")
                return
            }

            switch error {
            case ClientError.unauthorized: callbackExpectation.fulfill()
            default: XCTFail("Caught unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAuthenticateRequiresOAuthToBeConfigured() {

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.authenticate { (token, error) in

            guard let error = error else {
                XCTFail("Expected to catch an error.")
                return
            }

            switch error {
            case ClientError.unauthorized: callbackExpectation.fulfill()
            default: XCTFail("Caught unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
