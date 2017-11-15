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
    var client: Client!
    var testObject: TestSessionManager!
    
    override func setUp() {
        super.setUp()

        testSession = createTestSession()
        client = Client()
        testObject = TestSessionManager(client: client, testSession: testSession)
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

        let testSessionJSON = self.testSessionJSON()
        guard let uploadTargetsJSON = testSessionJSON[TestSession.Keys.uploads] as? [JSON] else {
            XCTFail()
            return
        }

        simulateTestUploads(numberOfUploads: uploadTargetsJSON.count)

        client.token = "randomToken"

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail("Caught unexpected request!")
                return
            }

            let expectedEndpoint = self.retrieveTestSessionEndpoint()

            XCTAssertEqual(networkRequest.url.absoluteString, self.client.baseURLPath + expectedEndpoint.path)
            XCTAssertEqual(networkRequest.method, expectedEndpoint.method)

            completion(testSessionJSON, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Failed with error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProcessTestSessionWhenRefershTimeoutOccurs() {

        client.token = "token"

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
        testObject = TestSessionManager(client: client, testSession: testSession)

        let callbackExpectation = expectation(description: "wait for callback")
        var retrieveTestSessionAttempts = 0
        let expectedTestSessionAttempts = 10

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail("Found unexpected request.")
                return
            }

            let expectedEndpoint = self.retrieveTestSessionEndpoint()
            let expectedURL = self.client.baseURLPath + expectedEndpoint.path

            guard networkRequest.url.absoluteString == expectedURL
                && networkRequest.method == expectedEndpoint.method else {
                    XCTFail()
                    return
            }

            retrieveTestSessionAttempts += 1

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

        client.token = "token"

        simulateTestUploads(numberOfUploads: 1)

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
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .goodTestFirst: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenFirstTestIsUnprocessible() {

        client.token = "token"

        simulateTestUploads(numberOfUploads: 1)

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
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .goodTestFirst: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenFirstTwoTestsAreNotReproducible() {

        client.token = "token"

        simulateTestUploads(numberOfUploads: 2)

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
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .notReproducibleTestFirst: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenFirstTwoTestsAreReproducible() {
        client.token = "token"

        simulateTestUploads(numberOfUploads: 2)

        var json = testSessionJSON(with: BestTestChoice.reproducible)

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
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .reproducibleTestFinal: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenResultsFromThreeTestsAreNotReproducible() {

        client.token = "token"

        var json = testSessionJSON(with: BestTestChoice.highestReference)

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
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ],
            [
                Test.Keys.id: "testid3",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId3"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail()
                return
            }

            let retrieveTestSessionURL = self.client.baseURLPath + self.retrieveTestSessionEndpoint().path
            let createUploadTargetURL = self.client.baseURLPath + self.createUploadTargetEndpoint().path

            switch networkRequest.url.absoluteString {
            case retrieveTestSessionURL:
                completion(json, nil)
            case createUploadTargetURL:

                let uploadTargetJSON: JSON = [
                    UploadTarget.Keys.id: "uploadId3",
                    UploadTarget.Keys.key: "uploadKey3",
                    UploadTarget.Keys.bucket: "uploadBucket3"
                ]

                completion(uploadTargetJSON, nil)
            default: XCTFail()
            }

        }

        simulateTestUploads(numberOfUploads: 3)

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .notReproducibleTestFinal: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenResultsFromThreeTestsAreReproducible() {
        client.token = "token"

        var json = testSessionJSON(with: BestTestChoice.reproducible)

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
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ],
            [
                Test.Keys.id: "testid3",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.complete.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId3"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail()
                return
            }

            let retrieveTestSessionURL = self.client.baseURLPath + self.retrieveTestSessionEndpoint().path
            let createUploadTargetURL = self.client.baseURLPath + self.createUploadTargetEndpoint().path

            switch networkRequest.url.absoluteString {
            case retrieveTestSessionURL:
                completion(json, nil)
            case createUploadTargetURL:

                let uploadTargetJSON: JSON = [
                    UploadTarget.Keys.id: "uploadId3",
                    UploadTarget.Keys.key: "uploadKey3",
                    UploadTarget.Keys.bucket: "uploadBucket3"
                ]

                completion(uploadTargetJSON, nil)
            default: XCTFail()
            }

        }

        simulateTestUploads(numberOfUploads: 3)

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .reproducibleTestFinal: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenResultsFromLastTestWereNotProcessible() {

        client.token = "token"

        simulateTestUploads(numberOfUploads: 2)

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
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7500).iso8601,
                Test.Keys.status: TestStatus.error.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .notProcessedTestFirst: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionUpdatesStateWhenResultsFromTwoTestsWereNotProcessible() {

        client.token = "token"

        simulateTestUploads(numberOfUploads: 2)

        var json = testSessionJSON()

        json[TestSession.Keys.tests] = [
            [
                Test.Keys.id: "testid1",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7000).iso8601,
                Test.Keys.status: TestStatus.error.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId1"
            ],
            [
                Test.Keys.id: "testid2",
                Test.Keys.breathDuration: 1234.0,
                Test.Keys.pef: 2345.0,
                Test.Keys.fev1: 3456.0,
                Test.Keys.takenAt: Date().addingTimeInterval(-7500).iso8601,
                Test.Keys.status: TestStatus.error.rawValue,
                Test.Keys.totalVolume: 5614.0,
                Test.Keys.upload: "uploadId2"
            ]
        ]

        mockNetwork.sendRequestStub = { request, completion in
            completion(json, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        switch testObject.state {
        case .notProcessedTestFinal: XCTAssertTrue(true)
        default: XCTFail("Found unexpected state: \(testObject.state)")
        }
    }

    func testProcessTestSessionWhenTestSessionDecodingFails() {

        client.token = "token"

        mockNetwork.sendRequestStub = { request, completion in
            completion([:], nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            guard let error = error else {
                XCTFail("Expected to catch an error.")
                return
            }

            switch error {
            case TestSessionManagerError.retrieveTestSessionFailed: callbackExpectation.fulfill()
            default: XCTFail("Caught unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProcessTestSessionWhenResponseContainsNoJSON() {

        client.token = "token"

        mockNetwork.sendRequestStub = { request, completion in
            completion(nil, nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        testObject.processTestSession { (error) in

            guard let error = error else {
                XCTFail("Expected to catch an error.")
                return
            }

            switch error {
            case TestSessionManagerError.retrieveTestSessionFailed: callbackExpectation.fulfill()
            default: XCTFail("Caught unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUploadRecordingWhenNoUnusedUploadTargetsAreAvailable() {

        let json: JSON = [
            TestSession.Keys.id: "testId",
            TestSession.Keys.patientId: "patientId",
            TestSession.Keys.startedAt: Date().addingTimeInterval(-8000).iso8601,
            TestSession.Keys.endedAt: Date().iso8601,
            TestSession.Keys.lungFunctionZone: LungFunctionZone.greenZone.rawValue,
            TestSession.Keys.respiratoryState: RespiratoryState.greenZone.rawValue,
            TestSession.Keys.referenceMetric: ReferenceMetric.pef.rawValue,
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
            TestSession.Keys.tests: []
        ]

        let expectedFilepath = "testpath"
        let expectedUploadTargetId = "uploadTargetId"
        let expectedUploadTargetKey = "uploadTargetKey"
        let expectedUploadTargetBucket = "uploadTargetBucket"

        testSession = createTestSession(with: json)
        testObject = TestSessionManager(client: client, testSession: testSession)

        client.token = "token"

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail()
                return
            }

            switch networkRequest.url.absoluteString {
            case self.client.baseURLPath + self.createUploadTargetEndpoint().path:

                completion([
                    UploadTarget.Keys.id: expectedUploadTargetId,
                    UploadTarget.Keys.key: expectedUploadTargetKey,
                    UploadTarget.Keys.bucket: expectedUploadTargetBucket
                    ], nil)
            default: XCTFail()
            }
        }

        mockNetwork.uploadFileStub = { filepath, bucket, key, completion in

            XCTAssertEqual(filepath, expectedFilepath)
            XCTAssertEqual(bucket, expectedUploadTargetBucket)
            XCTAssertEqual(key, expectedUploadTargetKey)

            completion(nil)
        }

        let callbackExpectation = expectation(description: "wait for callback")

        XCTAssertEqual(testSession.uploadTargets.count, 0)

        testObject.uploadRecording(atFilepath: expectedFilepath) { (error) in

            if let error = error {
                XCTFail("Caught unexpected error: \(error)")
                return
            }

            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(testSession.uploadTargets.count, 1)

        let uploadTarget = testSession.uploadTargets.first!

        XCTAssertEqual(uploadTarget.id, expectedUploadTargetId)
        XCTAssertEqual(uploadTarget.key, expectedUploadTargetKey)
        XCTAssertEqual(uploadTarget.bucket, expectedUploadTargetBucket)
    }

    func testUploadTargetWhenUploadTargetJSONIsUndecodable() {

        let json: JSON = [
            TestSession.Keys.id: "testId",
            TestSession.Keys.patientId: "patientId",
            TestSession.Keys.startedAt: Date().addingTimeInterval(-8000).iso8601,
            TestSession.Keys.endedAt: Date().iso8601,
            TestSession.Keys.lungFunctionZone: LungFunctionZone.greenZone.rawValue,
            TestSession.Keys.respiratoryState: RespiratoryState.greenZone.rawValue,
            TestSession.Keys.referenceMetric: ReferenceMetric.pef.rawValue,
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
            TestSession.Keys.tests: []
        ]

        let expectedFilepath = "testpath"
        let expectedUploadTargetId = "uploadTargetId"

        testSession = createTestSession(with: json)
        testObject = TestSessionManager(client: client, testSession: testSession)

        client.token = "token"

        mockNetwork.sendRequestStub = { request, completion in

            guard let networkRequest = request as? NetworkRequest else {
                XCTFail()
                return
            }

            switch networkRequest.url.absoluteString {
            case self.client.baseURLPath + self.createUploadTargetEndpoint().path:

                completion([
                    UploadTarget.Keys.id: expectedUploadTargetId,
                    ], nil)
            default: XCTFail()
            }
        }

        let callbackExpectation = expectation(description: "wait for callback")

        XCTAssertEqual(testSession.uploadTargets.count, 0)

        testObject.uploadRecording(atFilepath: expectedFilepath) { (error) in

            guard let error = error else {
                XCTFail("Expected to catch an error.")
                return
            }

            switch error {
            case TestSessionManagerError.uploadTargetCreationFailed: callbackExpectation.fulfill()
            default: XCTFail("Caught unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(testSession.uploadTargets.count, 0)
    }

    // MARK: - Helper Methods

    func testSessionJSON(with bestTestChoice: BestTestChoice? = nil) -> JSON {

        var json: JSON = [
            TestSession.Keys.id: "testId",
            TestSession.Keys.patientId: "patientId",
            TestSession.Keys.startedAt: Date().addingTimeInterval(-8000).iso8601,
            TestSession.Keys.endedAt: Date().iso8601,
            TestSession.Keys.lungFunctionZone: LungFunctionZone.greenZone.rawValue,
            TestSession.Keys.respiratoryState: RespiratoryState.greenZone.rawValue,
            TestSession.Keys.referenceMetric: ReferenceMetric.pef.rawValue,
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

        if let bestTestChoice = bestTestChoice {
            json[TestSession.Keys.bestTestChoice] = bestTestChoice.rawValue
        }

        return json
    }

    func createTestSession(with json: JSON? = nil) -> TestSession {
        let decoder = WingKit.JSONDecoder()
        return try! decoder.decode(TestSession.self, from: json ?? testSessionJSON())
    }

    func simulateTestUploads(numberOfUploads: Int) {
        for _ in 0 ..< numberOfUploads {
            testObject.uploadRecording(atFilepath: "testpath", completion: { error in })
        }
    }

    func retrieveTestSessionEndpoint() -> Endpoint {
        return TestSessionEndpoint.retrieve(patientId: self.testSession.patientId, sessionId: self.testSession.id)
    }

    func createUploadTargetEndpoint() -> Endpoint {
        return UploadTargetEndpoint.create(patientId: self.testSession.patientId, sessionId: self.testSession.id)
    }
}
