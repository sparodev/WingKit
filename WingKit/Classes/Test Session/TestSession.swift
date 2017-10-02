//
//  TestSession.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

enum BestTestChoice: Int {
    case reproducible = 1
    case highestReference

    var string: String {
        switch self {
        case .reproducible: return "reproducible"
        case .highestReference: return "highest reference"
        }
    }

    static func stringToEnum(_ string: String) -> BestTestChoice? {
        switch string {
        case "reproducible": return reproducible
        case "highest reference": return highestReference
        default: return nil
        }
    }
}

enum LungFunctionZone: Int {
    case greenZone = 1
    case yellowZone
    case redZone

    var string: String {
        switch self {
        case .greenZone: return "green zone"
        case .yellowZone: return "yellow zone"
        case .redZone: return "red zone"
        }
    }

    static func stringToEnum(_ string: String) -> LungFunctionZone? {
        switch string {
        case "green zone": return greenZone
        case "yellow zone": return yellowZone
        case "red zone": return redZone
        default: return nil
        }
    }
}

enum RespiratoryState: Int {
    case greenZone = 1
    case yellowZone
    case redZone
    case criticalZone

    var string: String {
        switch self {
        case .greenZone: return "green zone"
        case .yellowZone: return "yellow zone"
        case .redZone: return "red zone"
        case .criticalZone: return "critical zone"
        }
    }

    static func stringToEnum(_ string: String) -> RespiratoryState? {
        switch string {
        case "green zone": return greenZone
        case "yellow zone": return yellowZone
        case "red zone": return redZone
        case "critical zone": return criticalZone
        default: return nil
        }
    }
}

enum LocalTestFailureReason {
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

enum TestSessionState: Equatable {
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

func == (lhs: TestSessionState, rhs: TestSessionState) -> Bool {
    return lhs.code == rhs.code
}

public struct TestSession: Decodable {

    struct Keys {
        static let id = "id"
        static let startedAt = "startedAt"
        static let endedAt = "endedAt"
        static let lungFunctionZone = "lungFunctionZone"
        static let respiratoryState = "respiratoryState"
        static let bestTestChoice = "bestTestChoice"
        static let bestTest = "bestTest"
        static let tests = "tests"
        static let testSessionState = "testSessionState"
        static let metadata = "metadata"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let altitude = "altitude"
        static let floor = "floor"
        static let uploads = "uploads"
    }

    /// The identifier for the test session.
    var id: String

    /// The date/time for when the test session started.
    var startedAt: Date

    /// The state of the test session.
    var state: TestSessionState = .noTest

    /// The date/time for when the test session ended.
    var endedAt: Date?

    /// The lung function based on the result of the test.
    var lungFunctionZone: LungFunctionZone?

    /// The respiratory state based on the result of the test.
    var respiratoryState: RespiratoryState?

    /// The latitude of the device at time of session start.
    var latitude: Double?

    /// The longitude of the device at time of session start.
    var longitude: Double?

    /// The altitude of the device at time of session start.
    var altitude: Double?

    /// The estimated floor of the device at time of session start.
    var floor: Double?

    /// The test chosen as the best test candidate to derive results from.
    var bestTest: Test?

    /// The tests taken during the test session.
    var tests: [Test] = []

    /// The upload targets used to upload lung function recordings to.
    var uploadTargets: [UploadTarget] = []

    /// How the best test was chosen
    var bestTestChoice: BestTestChoice?

    init?(from decoder: JSONDecoder) {

        guard let json = decoder.json,
            let id = json[Keys.id] as? String,
            let startedAt = (json[Keys.startedAt] as? String)?.dateFromISO8601 else {
            return nil
        }

        self.id = id
        self.startedAt = startedAt

        endedAt = (json[Keys.endedAt] as? String)?.dateFromISO8601

        if let lungFunctionZoneString = json[Keys.lungFunctionZone] as? String,
            let lungFunctionZone = LungFunctionZone.stringToEnum(lungFunctionZoneString) {
            self.lungFunctionZone = lungFunctionZone
        }

        if let respiratoryStateString = json[Keys.respiratoryState] as? String,
            let respiratoryState = RespiratoryState.stringToEnum(respiratoryStateString) {
            self.respiratoryState = respiratoryState
        }

        if let bestTestChoiceString = json[Keys.bestTestChoice] as? String,
            let bestTestChoice = BestTestChoice.stringToEnum(bestTestChoiceString) {
            self.bestTestChoice = bestTestChoice
        }

        if let metadata = json[Keys.metadata] as? JSON {

            if let latitude = metadata[Keys.latitude] as? Double {
                self.latitude = latitude
            }

            if let longitude = metadata[Keys.longitude] as? Double {
                self.longitude = longitude
            }

            if let altitude = metadata[Keys.altitude] as? Double {
                self.altitude = altitude
            }

            if let floor = metadata[Keys.floor] as? Double {
                self.floor = floor
            }
        }

        if let bestTestJSON = json[Keys.bestTest] as? JSON {

            do {
                let decoder = JSONDecoder()
                self.bestTest = try decoder.decode(Test.self, from: bestTestJSON)
            } catch {
                return nil
            }

        }

        if let testsJSON = json[Keys.tests] as? [JSON] {

            var tests = [Test]()
            for testJSON in testsJSON {

                let decoder = JSONDecoder()
                do {
                    let test = try decoder.decode(Test.self, from: testJSON)
                    tests.append(test)
                } catch {
                    return nil
                }
            }

            self.tests = tests
        }

        if let uploadTargetsJSON = json[Keys.uploads] as? [JSON] {

            var uploadTargets = [UploadTarget]()
            for targetJSON in uploadTargetsJSON {

                let decoder = JSONDecoder()
                do {
                    let target = try decoder.decode(UploadTarget.self, from: targetJSON)
                    uploadTargets.append(target)
                } catch {
                    return nil
                }
            }

            self.uploadTargets = uploadTargets
        }
    }
}
