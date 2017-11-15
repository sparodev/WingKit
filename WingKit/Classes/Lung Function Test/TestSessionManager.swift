//
//  TestSessionManager.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

/// The `TestSessionState` enum describes the various states a test session can be in.
public enum TestSessionState {

    /// Indicates that no tests have been performed during the session.
    case noTest

    /// Indicates that the test session includes one successful test.
    case goodTestFirst

    /// Indicates that the test session includes one test that wasn't able to be processed.
    case notProcessedTestFirst

    /// Indicates that the test session includes two complete tests that aren't reproducible.
    case notReproducibleTestFirst

    /// Indicates that the test session has concluded with non-reproducible results.
    case notReproducibleTestFinal

    /// Indicates that the test session has concluded with reproducible results.
    case reproducibleTestFinal

    /// Indiciates that the test session has concluded with at least two non-processable tests.
    case notProcessedTestFinal
}

/// The `TestSessionManagerError` enum describes domain specific errors for the `TestSessionManager` class.
public enum TestSessionManagerError: Error {

    /// Indicates the specified test session could not be loaded.
    case retrieveTestSessionFailed

    /// Indicates a upload target could not be created.
    case createUploadTargetFailed

    /// Indicates the processing request has timed out.
    case processingTimeout

    /// Indicates that an upload target could not be created to upload a test recording to.
    case uploadTargetCreationFailed

    /// Indicates the test recording failed to upload to S3.
    case testUploadFailed
}

/**
 The `TestSessionManager` class is responsible for keeping track of a test session's state and provides an inteface to
 the necessary Wing API endpoints to perform a lung function test.
 */
public class TestSessionManager {

    // MARK: - Properties

    /// The Wing client used to interface with the Wing REST API.
    public fileprivate(set) var client: Client!

    /// The state of the test session.
    public fileprivate(set) var state: TestSessionState = .noTest

    /// The active test session.
    public fileprivate(set) var testSession: TestSession

    fileprivate var usedUploadTargetIds = [String]()

    /// The number of tests that are allowed to fail processing before the test session is considered invalid.
    public let failedTestsThreshold = 2

    /// The number of tests that are allowed to fail due to local failure reasons before the test session is considered invalid.s
    public let localTestFailureThreshold = 2

    /// The interval at which the server will be pinged to check if processing is complete.
    public let processingPollingInterval: Double = 0.8

    /// The threshold that represents the number of times the app should attempt to refresh the test session.
    public let processingTimeoutThreshold = 10

    /// The number of attempts the test session has been refreshed in effort to determine the processing state.
    public fileprivate(set) var numberOfProcessingAttempts = 0

    // MARK: - Initialization

    /// Initializes the `TestSessionManager` with the test session passed in as an argument.
    public init(client: Client, testSession: TestSession) {
        self.client = client
        self.testSession = testSession
    }

    fileprivate func resetProcessingAttemptsCount() {
        numberOfProcessingAttempts = 0
    }

    // MARK: - Process Test

    /**
     Retrieves and applies the updated details of the associated test session.

     - Throws:
         - `ClientError.unauthorized` if the `token` hasn't been set on the client.
         - `TestSessionManagerError.processingTimeout` if number of processing attempts exceeds the timeout threshold.
         - `TestSessionManagerError.retrieveTestSessionFailed` if the response doesn't contain the test session.
         - `NetworkError.unacceptableStatusCode` if an failure status code is received in the response.
     */
    public func processTestSession(completion: @escaping (Swift.Error?) -> Void) {

        guard numberOfProcessingAttempts < processingTimeoutThreshold else {
            self.resetProcessingAttemptsCount()
            completion(TestSessionManagerError.processingTimeout)
            return
        }

        client.retrieveTestSession(withId: testSession.id, patientId: testSession.patientId) { (testSession, error) in

            guard let testSession = testSession else {

                self.resetProcessingAttemptsCount()

                guard let error = error else {
                    completion(TestSessionManagerError.retrieveTestSessionFailed)
                    return
                }

                switch error {
                case NetworkError.invalidResponse, DecodingError.decodingFailed:
                    completion(TestSessionManagerError.retrieveTestSessionFailed)
                default: completion(error)
                }

                return
            }

            self.testSession.merge(with: testSession)

            let processedTestsCount = testSession.tests.filter({
                return $0.status == .complete || $0.status == .error
            }).count

            if processedTestsCount == self.usedUploadTargetIds.count
                && processedTestsCount == testSession.tests.count {

                self.updateState()
                self.resetProcessingAttemptsCount()

                completion(nil)

            } else {

                self.numberOfProcessingAttempts += 1

                Timer.after(self.processingPollingInterval, {
                    self.processTestSession(completion: completion)
                })
            }
        }
    }


    // MARK: - Upload Recording

    /**
     Uploads the recording at the specified filepath to Amazon S3 to initiate processing.

     - Parameters:
        - filepath: The filepath for the lung function test recording file.
        - completion: A callback closure that gets invoked after receiving the response from the upload request.
            - error: The error that occurred while uploading the recording (Optional).

     - Throws:
        - `ClientError.unauthorized` if the `token` hasn't been set on the client.
        - `NetworkError.unacceptableStatusCode` if an failure status code is received in the response.
        - `TestSessionManagerError.uploadTargetCreationFailed` if the request to create a upload target failed.
        - `TestSessionmanagerError.testUploadFailed` if uploading the test recording failed.

     */
    public func uploadRecording(atFilepath filepath: String, completion: @escaping (_ error: Swift.Error?) -> Void) {
        getUploadTarget { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                completion(error)
                return
            }

            self.usedUploadTargetIds.append(uploadTarget.id)
            self.client.uploadFile(atFilepath: filepath, to: uploadTarget, completion: { error in

                if let error = error {

                    print("Test upload failed with error: \(error)")
                    completion(TestSessionManagerError.testUploadFailed)
                    return
                }

                completion(nil)
            })
        }
    }

    fileprivate func getUploadTarget(completion: @escaping (UploadTarget?, Swift.Error?) -> Void) {
        if let uploadTarget = testSession.uploadTargets.filter({ !usedUploadTargetIds.contains($0.id) }).first {
            completion(uploadTarget, nil)
            return
        }

        self.client.createUploadTarget(forTestSessionId: testSession.id,
                                       patientId: testSession.patientId) { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {

                guard let error = error else {
                    completion(nil, TestSessionManagerError.uploadTargetCreationFailed)
                    return
                }

                switch error {
                case NetworkError.invalidResponse, DecodingError.decodingFailed:
                    completion(nil, TestSessionManagerError.uploadTargetCreationFailed)
                default: completion(nil, error)
                }

                return
            }

            self.testSession.uploadTargets.append(uploadTarget)

            completion(uploadTarget, nil)
        }
    }

    fileprivate func updateState() {
        var newState = state

        switch testSession.bestTestChoice {
        case .some(.reproducible):
            newState = .reproducibleTestFinal
        case .some(.highestReference):
            newState = .notReproducibleTestFinal
        case .none:

            guard let mostRecentTest = testSession.tests.sorted(by: {

                guard let lhsTakenAt = $0.takenAt else {
                    return false
                }

                guard let rhsTakenAt = $1.takenAt else {
                    return true
                }

                return lhsTakenAt.compare(rhsTakenAt) == .orderedAscending

            }).first else { break }

            switch mostRecentTest.status {
            case .error:
                let failedTests = testSession.tests.filter({
                    return $0.status == .error
                })

                newState = failedTests.count >= failedTestsThreshold ? .notProcessedTestFinal : .notProcessedTestFirst

            case .complete:
                let completeTests = testSession.tests.filter({
                    return $0.status == .complete
                })

                switch completeTests.count {
                case 1: newState = .goodTestFirst
                case 2: newState = .notReproducibleTestFirst
                default: break
                }
            default: break
            }
        }

        state = newState
    }
}
