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
    case update(sessionId: String)

    var path: String {
        switch self {
        case .create: return "/test-sessions"
        case .retrieve(let sessionId): return "/test-sessions/\(sessionId)"
        case .update(let sessionId): return "/test-sessions/\(sessionId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .retrieve: return .get
        case .update: return .put
        }
    }
}

extension Client {

    static func createTestSession(completion: @escaping (TestSession?, Error?) -> Void) {

        var request: URLRequestConvertible
        do {
            request = try self.request(for: TestSessionEndpoint.create)
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

            let decoder = JSONDecoder()
            do {
                let testSession = try decoder.decode(TestSession.self, from: json)
                completion(testSession, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
