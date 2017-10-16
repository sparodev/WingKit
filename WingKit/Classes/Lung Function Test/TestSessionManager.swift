//
//  TestSessionManager.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/4/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

public protocol TestSessionManagerDelegate: class {

}

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

public enum TestSessionState: Equatable {
    case noTest
    case goodTestFirst
    case notProcessedTestFirst
    case notReproducibleTestFirst
    case notReproducibleTestFinal
    case reproducibleTestFinal
    case notProcessedTestFinal
    case testSessionInterrupted(reason: LocalTestFailureReason)

    static func state(forCode code: Int) -> TestSessionState? {
        switch code {
        case 0: return .noTest
        case 1: return .goodTestFirst
        case 2: return .reproducibleTestFinal
        case 100: return .notProcessedTestFirst
        case 101: return .notReproducibleTestFirst
        case 102: return .notReproducibleTestFinal
        case 103: return .notProcessedTestFinal
        case 200: return .testSessionInterrupted(reason: .internetDisconnected)
        case 201: return .testSessionInterrupted(reason: .sensorDisconnected)
        case 202: return .testSessionInterrupted(reason: .animationThresholdNotMet)
        default: return nil
        }
    }

    var code: Int {
        switch self {
        case .noTest: return 0
        case .goodTestFirst: return 1
        case .reproducibleTestFinal: return 2
        case .notProcessedTestFirst: return 100
        case .notReproducibleTestFirst: return 101
        case .notReproducibleTestFinal: return 102
        case .notProcessedTestFinal: return 103
        case .testSessionInterrupted(let reason):
            switch reason {
            case .internetDisconnected: return 200
            case .sensorDisconnected: return 201
            case .animationThresholdNotMet: return 202
            }
        }
    }
}

public func == (lhs: TestSessionState, rhs: TestSessionState) -> Bool {
    return lhs.code == rhs.code
}

public class TestSessionManager {

    public enum Error: Swift.Error {
        case testSessionNotFound
        case uploadTargetCreationFailed
        case invalidUploadTarget
        case invalidRecording
    }

    /// The state of the test session.
    public fileprivate(set) var state: TestSessionState = .noTest

    var testSession: TestSession

    fileprivate var activeUploadTarget: UploadTarget?
    fileprivate var usedUploadTargetIds = [String]()

    let failedTestsThreshold = 2
    let localTestFailureThreshold = 2

    /// The interval at which the server will be pinged to check if processing is complete.

    let processingPollingInterval: Double = 0.8

    /// The threshold that represents the number of times the app should attempt to refresh the test session.

    let processingTimeoutThreshold = 10

    /// The number of attempts the test session has been refreshed in effort to determine the processing state.

    var numberOfProcessingAttempts = 0

    public init(testSession: TestSession) {
        self.testSession = testSession
    }

    public func refreshTestSession(completion: @escaping (Swift.Error?) -> Void) {

        guard let _ = activeUploadTarget else {
            completion(Error.invalidUploadTarget)
            return
        }

        Client.retrieveTestSession(withId: testSession.id) { (testSession, error) in

            guard let testSession = testSession else {
                if let error = error {
                    completion(error)
                } else {
                    completion(Error.testSessionNotFound)
                }

                return
            }

            self.testSession = testSession

            let completedTests = testSession.tests.filter {
                return $0.status == .complete || $0.status == .error
            }

            if completedTests.count == self.usedUploadTargetIds.count
                && completedTests.count == testSession.tests.count {

                completion(nil)

            } else {

                Timer.after(self.processingPollingInterval, {
                    self.refreshTestSession(completion: completion)
                })
            }

            completion(nil)
        }
    }

    public func uploadRecording(atFilepath filepath: String, completion: @escaping (Swift.Error?) -> Void) {
        getUploadTarget { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                completion(error)
                return
            }

            self.activeUploadTarget = uploadTarget
            self.usedUploadTargetIds.append(uploadTarget.id)

            Client.uploadFile(atFilepath: filepath, to: uploadTarget, completion: completion)
        }
    }

    func getUploadTarget(completion: @escaping (UploadTarget?, Swift.Error?) -> Void) {
        if let uploadTarget = testSession.uploadTargets.filter({ !usedUploadTargetIds.contains($0.id) }).first {
            completion(uploadTarget, nil)
            return
        }

        Client.createUploadTarget(forTestSessionId: testSession.id) { (uploadTarget, error) in
            guard let uploadTarget = uploadTarget else {
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(nil, Error.uploadTargetCreationFailed)
                }
                return
            }

            self.testSession.uploadTargets.append(uploadTarget)

            completion(uploadTarget, nil)
        }
    }

    public func updateState() {
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
