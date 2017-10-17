//
//  Client.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

struct OAuthCredentials {
    var id: String
    var secret: String
}

struct OAuthParameterKeys {
    static let id = "id"
    static let secret = "secret"
}

enum ClientError: Error {
    case invalidURL
    case unauthorized
}

enum AuthenticationEndpoint: Endpoint {
    case authenticate

    var path: String {
        switch self {
        case .authenticate: return "/authenticate"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .authenticate: return .post
        }
    }
}

public class Client {

    static let baseURLPath = "https://api-development.mywing.io/api/v2"
    static var oauth: OAuthCredentials? = nil
    static var token: String? {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IktyNDJ5b2pHdzM4V3oiLCJ0eXBlIjoiYXV0aCIsImtleUdlbiI6IjEyRUJBYmxnTHJOSlAiLCJpYXQiOjE1MDc1NjQ0NDUsImV4cCI6MTUzOTEwMDQ0NX0.Tz1bn1dq0NQaHA-kEo9XQx8ueTTMFLc32j6p4eQy6z0"
    }

    static func request(for endpoint: Endpoint,
                        parameters: [String: Any]? = nil,
                        headers: [String: String]? = nil) throws -> NetworkRequest {

        guard let url = url(for: endpoint) else {
            throw ClientError.invalidURL
        }

        var updatedHeaders = headers ?? [:]

        if updatedHeaders["Accept"] == nil {
            updatedHeaders["Accept"] = "application/json"
        }

        if updatedHeaders["Content-Type"] == nil {
            updatedHeaders["Content-Type"] = "application/json"
        }

        if let token = token {
            updatedHeaders["Authorization"] = token
        }

        return NetworkRequest(url: url, method: endpoint.method, parameters: parameters, headers: updatedHeaders)
    }

    fileprivate static func url(for endpoint: Endpoint) -> URL? {
        return URL(string: baseURLPath + endpoint.path)
    }

    /**
     Authenticates the application with the Wing API using the assigned Client ID/Secret.
     */
    public static func authenticate(completion: @escaping (String?, Error?) -> Void) {

        guard let oauth = oauth else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(
                for: AuthenticationEndpoint.authenticate,
                parameters: [
                    OAuthParameterKeys.id: oauth.id,
                    OAuthParameterKeys.secret: oauth.secret
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

            guard let json = json,
                let token = json["token"] as? String else {
                completion(nil, NetworkError.invalidResponse)
                return
            }

            completion(token, nil)
        }
    }
}
