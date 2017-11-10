//
//  Client+TestSession.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

enum TestSessionEndpoint: Endpoint {

    case create
    case retrieve(sessionId: String)

    var path: String {
        switch self {
        case .create: return "/patients/5yEwdO6MVR8ZA/test-sessions"
        case .retrieve(let sessionId): return "/patients/5yEwdO6MVR8ZA/test-sessions/\(sessionId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .retrieve: return .get
        }
    }

    var acceptableStatusCodes: [Int] {
        switch self {
        case .create: return [200]
        case .retrieve: return [200]
        }
    }
}

public enum BiologlicalSex: String {
    case male
    case female
}

public enum Ethnicity: String {
    case other
    case nativeAmerican = "american indian or alaskan native"
    case asian
    case black = "black or african american"
    case pacificIslander = "native hawaiian or pacific islander"
    case whiteNonHispanic = "white (non-hispanic)"
    case whiteHispanic = "white (hispanic)"
    case twoOrMore = "two or more"
}

public struct PatientData {
    /// The unique ID for the patient.
    public var id: String

    /// The patient's biological sex.
    public var biologicalSex: BiologlicalSex

    /// The patient's ethnicity.
    public var ethnicity: Ethnicity

    /// The patient's height (in inches).
    public var height: Int

    /// The patient's age.
    public var age: Int

    public init(id: String, biologicalSex: BiologlicalSex, ethnicity: Ethnicity, height: Int, age: Int) {
        self.id = id
        self.biologicalSex = biologicalSex
        self.ethnicity = ethnicity
        self.height = height
        self.age = age
    }
}

public extension Client {

    /**
     Sends a request to the Wing REST API to create a test session.

     - parameter patientData: The data for the patient that the test session is being created for.
     - parameter completion: The callback closure  that will get invoked upon the request finishing.
     - parameter testSession: The test session object that represents the created test session. (Optional)
     - parameter error: The error that occurred while performing the network request. (Optional)
     */
    public func createTestSession(with patientData: PatientData,
                                         completion: @escaping (_ testSession: TestSession?, _ error: Error?) -> Void) {

        guard let token = token else {
            completion(nil, ClientError.unauthorized)
            return
        }

        guard let birthdate = Calendar.current.date(byAdding: .year, value: -patientData.age, to: Date()) else {
            completion(nil, ClientError.invalidPatientData)
            return
        }

        let parameters: JSON = [
            "patient": [
                "externalId": patientData.id,
                "biologicalSex": patientData.biologicalSex.rawValue,
                "ethnicity": patientData.ethnicity.rawValue,
                "dob": birthdate.iso8601,
                "height": patientData.height
            ],
            "localTimezone": Date().iso8601
        ]

        var request: URLRequestConvertible
        do {
            request = try self.request(for: TestSessionEndpoint.create,
                                       parameters: parameters,
                                       headers: ["Authorization": token])
        } catch {
            return completion(nil, error)
        }

        Network.shared.send(request: request) { (json, error) in

            if let error = error {
                completion(nil, error)
                return
            }

            guard let json = json else {
                completion(nil, NetworkError.invalidResponse)
                return
            }

            self.parseTestSession(fromJSON: json, completion: completion)
        }
    }

    /**
     Sends a request to retrieve the details for the test session for the specified ID.

     - parameter id: The identifier for the test session.
     - parameter completion: The callback closure that will get invoked upon the request finishing.
     - parameter testSession: The test session object that represents the retrieved test session. (Optional)
     - parameter error: The error that occurred while performing the network request. (Optional)
     */
    public func retrieveTestSession(withId id: String, completion: @escaping (_ testSession: TestSession?, _ error: Error?) -> Void) {

        guard let token = token else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(for: TestSessionEndpoint.retrieve(sessionId: id),
                                       headers: ["Authorization": token])
        } catch {
            return completion(nil, error)
        }

        Network.shared.send(request: request) { (json, error) in

            if let error = error {
                return completion(nil, error)
            }

            guard let json = json else {
                return completion(nil, NetworkError.invalidResponse)
            }

            self.parseTestSession(fromJSON: json, completion: completion)
        }
    }

    fileprivate func parseTestSession(fromJSON json: JSON, completion: (TestSession?, Error?) -> Void) {
        let decoder = JSONDecoder()
        do {
            let testSession = try decoder.decode(TestSession.self, from: json)
            completion(testSession, nil)
        } catch {
            completion(nil, error)
        }
    }
}
