//
//  Client+TestSession.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

internal enum TestSessionEndpoint: Endpoint {

    case create
    case retrieve(patientId: String, sessionId: String)

    var path: String {
        switch self {
        case .create: return "/patients/5yEwdO6MVR8ZA/test-sessions"
        case .retrieve(let patientId, let sessionId): return "/patients/\(patientId)/test-sessions/\(sessionId)"
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

/// The options for the biological sex of the patient.
public enum BiologlicalSex: String {

    /// Male.
    case male

    /// Female.
    case female
}

/// The options for the ethnicity of the patient.
public enum Ethnicity: String {

    /// Other ethnicity.
    case other

    /// Native American or Alaskan Native
    case nativeAmerican = "american indian or alaskan native"

    /// Asian
    case asian

    /// Black or African American
    case black = "black or african american"

    /// Native Hawaiian or Pacific Islander
    case pacificIslander = "native hawaiian or pacific islander"

    /// White (Non-hispanic)
    case whiteNonHispanic = "white (non-hispanic)"

    /// White (Hispanic)
    case whiteHispanic = "white (hispanic)"

    /// Two or more ethnicities
    case twoOrMore = "two or more"
}

/**
 Represents the payload that is sent along when creating a test session. It is used to calculate the predicated PEF and
 FEV1 values for the associated patient.
 */
public struct PatientData {

    /// The unique ID for the patient.
    public var id: String

    /// The patient's biological sex.
    public var biologicalSex: BiologlicalSex?

    /// The patient's ethnicity.
    public var ethnicity: Ethnicity?

    /// The patient's height (in inches).
    public var height: Int?

    /// The patient's age.
    public var age: Int?

    /**
     Initializes a `PatientData` structure.
     */
    public init(id: String, biologicalSex: BiologlicalSex?, ethnicity: Ethnicity?, height: Int?, age: Int?) {
        self.id = id
        self.biologicalSex = biologicalSex
        self.ethnicity = ethnicity
        self.height = height
        self.age = age
    }

    internal func json() -> JSON {

        var json: JSON = [
            "externalId": id
        ]

        if let biologicalSex = biologicalSex,
            let ethnicity = ethnicity,
            let height = height,
            let age = age,
            let birthdate = Calendar.current.date(byAdding: .year, value: -age, to: Date()) {

            json["biologicalSex"] = biologicalSex.rawValue
            json["ethnicity"] = ethnicity.rawValue
            json["dob"] = birthdate.iso8601
            json["height"] = height
        }

        return json
    }
}

public extension Client {

    // MARK: - Test Sessions

    /**
     Creates a test session for a person with the specified patient data.

     **Note: Requires token authentication to be configured.**

     
     - Parameters:
         - patientData: The data for the patient that the test session is being created for.
         - completion: The callback closure  that will get invoked upon the request finishing.
         - testSession: The test session object that represents the created test session. (Optional)
         - error: The error that occurred while performing the network request. (Optional)

     - Throws:
        - `ClientError.unauthorized` if the `token` hasn't been set on the client.
        - `NetworkError.invalidResponse` if an invalid response was recieved.
        - `NetworkError.unacceptableStatusCode` if an failure status code is received in the response.
        - `DecodingError.decodingFailed` if the response json could not be decoded.
     */
    public func createTestSession(with patientData: PatientData,
                                  completion: @escaping (_ testSession: TestSession?, _ error: Error?) -> Void) {

        guard token != nil else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(
                for: TestSessionEndpoint.create,
                parameters: [
                    "localTimezone": Date().iso8601,
                    "patient": patientData.json()
                ]
            )
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
     Retrieves the details of the test session with the specified ID.

     **Note: Requires token authentication to be configured.**

     - parameter id: The identifier for the test session.
     - parameter completion: The callback closure that will get invoked upon the request finishing.
     - parameter testSession: The test session object that represents the retrieved test session. (Optional)
     - parameter error: The error that occurred while performing the network request. (Optional)

     - Throws:
         - `ClientError.unauthorized` if the `token` hasn't been set on the client.
         - `NetworkError.invalidResponse` if an invalid response was recieved.
         - `NetworkError.unacceptableStatusCode` if an failure status code is received in the response.
         - `DecodingError.decodingFailed` if the response json could not be decoded.
     */
    public func retrieveTestSession(withId id: String, patientId: String, completion: @escaping (_ testSession: TestSession?, _ error: Error?) -> Void) {

        guard token != nil else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(for: TestSessionEndpoint.retrieve(patientId: patientId, sessionId: id))
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
