//
//  TestSession.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

public enum BestTestChoice: Int {
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

public enum LungFunctionZone: Int {
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

public enum RespiratoryState: Int {
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
    public var id: String

    /// The date/time for when the test session started.
    public var startedAt: Date

    /// The date/time for when the test session ended.
    public var endedAt: Date?

    /// The lung function based on the result of the test.
    public var lungFunctionZone: LungFunctionZone?

    /// The respiratory state based on the result of the test.
    public var respiratoryState: RespiratoryState?

    /// The latitude of the device at time of session start.
    public var latitude: Double?

    /// The longitude of the device at time of session start.
    public var longitude: Double?

    /// The altitude of the device at time of session start.
    public var altitude: Double?

    /// The estimated floor of the device at time of session start.
    public var floor: Double?

    /// The test chosen as the best test candidate to derive results from.
    public var bestTest: Test?

    /// The tests taken during the test session.
    public var tests: [Test] = []

    /// The upload targets used to upload lung function recordings to.
    var uploadTargets: [UploadTarget] = []

    /// How the best test was chosen
    public var bestTestChoice: BestTestChoice?

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
