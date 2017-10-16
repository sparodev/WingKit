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
        case .create: return "/test-sessions"
        case .retrieve(let sessionId): return "/test-sessions/\(sessionId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .retrieve: return .get
        }
    }
}

public extension Client {

    public static func createTestSession(completion: @escaping (TestSession?, Error?) -> Void) {

        guard let token = token else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(for: TestSessionEndpoint.create,
                                       parameters: ["localTimezone": Date().iso8601],
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

            parseTestSession(fromJSON: json, completion: completion)
        }
    }

    public static func retrieveTestSession(withId id: String, completion: @escaping (TestSession?, Error?) -> Void) {

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

            parseTestSession(fromJSON: json, completion: completion)
        }
    }

    static fileprivate func parseTestSession(fromJSON json: JSON, completion: (TestSession?, Error?) -> Void) {
        let decoder = JSONDecoder()
        do {
            let testSession = try decoder.decode(TestSession.self, from: json)
            completion(testSession, nil)
        } catch {
            completion(nil, error)
        }
    }
}
