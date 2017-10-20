//
//  TestSession.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

/// Represents the method used to determine the result (best test) of a test session.
public enum BestTestChoice: String {

    /// Indicates that the test session had reproducible results to derive the best test from.
    case reproducible = "reproducible"

    /// Indicates that the test session did not have reproducible results, thus the test with highest reference value was used as the result.
    case highestReference = "highest reference"
}


/// Represents the Peak Flow measurement zones that doctors use when developing an asthma management plan.
public enum LungFunctionZone: String {

    /// Indicates that 80 to 100 percent of the usual or normal peak flow readings are clear.
    case greenZone = "green zone"

    /// Indicates that 50 to 79 percent of the usual or normal peak flow readings.
    case yellowZone = "yellow zone"

    /// Indicates that less than 50 percent of the usual or normal peak flow readings.
    case redZone = "red zone"
}

public enum RespiratoryState: String {
    case greenZone = "green zone"
    case yellowZone = "yellow zone"
    case redZone = "red zone"
    case criticalZone = "critical zone"
}

/**
 The `TestSession` struct represents a session of multiple lung function tests.
 */
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
            let lungFunctionZone = LungFunctionZone(rawValue: lungFunctionZoneString) {
            self.lungFunctionZone = lungFunctionZone
        }

        if let respiratoryStateString = json[Keys.respiratoryState] as? String,
            let respiratoryState = RespiratoryState(rawValue: respiratoryStateString) {
            self.respiratoryState = respiratoryState
        }

        if let bestTestChoiceString = json[Keys.bestTestChoice] as? String,
            let bestTestChoice = BestTestChoice(rawValue: bestTestChoiceString) {
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

    mutating func merge(with testSession: TestSession) {

        endedAt = testSession.endedAt
        lungFunctionZone = testSession.lungFunctionZone
        respiratoryState = testSession.respiratoryState
        bestTestChoice = testSession.bestTestChoice

        if let latitude = testSession.latitude {
            self.latitude = latitude
        }

        if let longitude = testSession.longitude {
            self.longitude = longitude
        }

        if let altitude = testSession.altitude {
            self.altitude = altitude
        }

        if let floor = testSession.floor {
            self.floor = floor
        }

        if let bestTest = testSession.bestTest {
            self.bestTest = bestTest
        }

        if !testSession.tests.isEmpty {
            self.tests = testSession.tests
        }

        if !testSession.uploadTargets.isEmpty {
            self.uploadTargets = testSession.uploadTargets
        }
    }
}
