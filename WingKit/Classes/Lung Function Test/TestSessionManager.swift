//
//  TestSessionManager.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

public enum LocalTestFailureReason {
    case sensorDisconnected
    case internetDisconnected
    case animationThresholdNotMet

    var title: String {
        switch self {
        case .sensorDisconnected: return "Sensor Error"
        case .internetDisconnected: return "Internet Error"
        case .animationThresholdNotMet: return "Processing Error"
        }
    }

    var subtitle: String {
        switch self {
        case .sensorDisconnected: return "Where's the sensor?"
        case .internetDisconnected: return "No Internet Connection"
        case .animationThresholdNotMet: return "Something went wrong!"
        }
    }

    var message: String {
        switch self {
        case .sensorDisconnected:
            return "Be sure Wing is plugged in and be careful not to pull on the cord when blowing into Wing!"
        case .internetDisconnected:
            return "You must be connected to the internet in order to take a test. "
                + "Please fix your connection and try again."
        case .animationThresholdNotMet:
            return "Let's try doing that test again!"
        }
    }
}

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

    /// Indicates that the most recent test failed due to a local failure reason.
    case testSessionInterrupted(reason: LocalTestFailureReason)
}

/// The `TestSessionManagerError` enum describes domain specific errors for the `TestSessionManager` class.
public enum TestSessionManagerError: Error {
    case testSessionNotFound
    case uploadTargetCreationFailed
    case invalidUploadTarget
    case invalidRecording
}

/**
 The `TestSessionManager` keeps track of a test session's state and also is the mediator for all the necessary network requests that occur during a test session.
 */
public class TestSessionManager {

    /// The state of the test session.
    public fileprivate(set) var state: TestSessionState = .noTest

    public fileprivate(set) var testSession: TestSession

    fileprivate var usedUploadTargetIds = [String]()

    /// The number of tests that are allowed to fail processing before the test session is considered invalid.
    public let failedTestsThreshold = 2

    /// The number of tests that are allowed to fail due to local failure reasons before the test session is considered invalid.s
    public let localTestFailureThreshold = 2

    /// The interval at which the server will be pinged to check if processing is complete.s
    let processingPollingInterval: Double = 0.8

    /// The threshold that represents the number of times the app should attempt to refresh the test session.
    let processingTimeoutThreshold = 10

    /// The number of attempts the test session has been refreshed in effort to determine the processing state.
    var numberOfProcessingAttempts = 0


    /// Initializes the `TestSessionManager` with the test session passed in as an argument.
    public init(testSession: TestSession) {
        self.testSession = testSession
    }

    /**
     Retrieves and applies the updated details of the associated test session.

     - throws:
     */
    public func refreshTestSession(completion: @escaping (Swift.Error?) -> Void) {

        Client.retrieveTestSession(withId: testSession.id) { (testSession, error) in

            guard let testSession = testSession else {
                if let error = error {
                    completion(error)
                } else {
                    completion(TestSessionManagerError.testSessionNotFound)
                }

                return
            }

            self.testSession.merge(with: testSession)

            let completedTests = testSession.tests.filter {
                return $0.status == .complete || $0.status == .error
            }

            if completedTests.count == self.usedUploadTargetIds.count
                && completedTests.count == testSession.tests.count {

                self.updateState()

                completion(nil)

            } else {

                Timer.after(self.processingPollingInterval, {
                    self.refreshTestSession(completion: completion)
                })
            }
        }
    }

    public func uploadRecording(atFilepath filepath: String, completion: @escaping (Swift.Error?) -> Void) {
        getUploadTarget { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                completion(error)
                return
            }

            self.usedUploadTargetIds.append(uploadTarget.id)

            Client.uploadFile(atFilepath: filepath, to: uploadTarget, completion: completion)
        }
    }

    fileprivate func getUploadTarget(completion: @escaping (UploadTarget?, Swift.Error?) -> Void) {
        if let uploadTarget = testSession.uploadTargets.filter({ !usedUploadTargetIds.contains($0.id) }).first {
            completion(uploadTarget, nil)
            return
        }

        Client.createUploadTarget(forTestSessionId: testSession.id) { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(nil, TestSessionManagerError.uploadTargetCreationFailed)
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
