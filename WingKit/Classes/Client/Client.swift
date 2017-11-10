//
//  Client.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

public struct OAuthCredentials {
    public var id: String
    public var secret: String

    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }
}

struct OAuthParameterKeys {
    static let id = "id"
    static let secret = "secret"
}

public enum ClientError: Error {
    case invalidURL
    case unauthorized
    case invalidPatientData
}

fileprivate enum AuthenticationEndpoint: Endpoint {
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

    var acceptableStatusCodes: [Int] {
        switch self {
        case .authenticate: return [200]
        }
    }
}

/**
 The 'Client' class acts as the interface for the Wing REST API. All Wing API Requests are routed through this class
 to apply the necessary authentication to the requests.
 */

public class Client {

    // MARK: - Properties

    public static let baseURLPath = "https://api-development.mywing.io/api/v2"

    /// The OAuth credentials required to authenticate with the Wing API.
    public static var oauth: OAuthCredentials? = nil

    /// The authorization token used to make authorized requests.
    public static var token: String? {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IktyNDJ5b2pHdzM4V3oiLCJ0eXBlIjoiYXV0aCIsImtleUdlbiI6IjEyRUJBYmxnTHJOSlAiLCJpYXQiOjE1MDk0NzU1ODcsImV4cCI6MTU0MTAxMTU4N30.PG6wEYDBwuZeWaUhIQGRPtH1UwiFqBXHs-zOqkuP3CI"
    }

    internal static func request(for endpoint: Endpoint,
                                parameters: [String: Any]? = nil,
                                headers: [String: String]? = nil) throws -> NetworkRequest {

        guard let url = URL(string: baseURLPath + endpoint.path) else {
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

        return NetworkRequest(url: url, acceptableStatusCodes: endpoint.acceptableStatusCodes,
                              method: endpoint.method, parameters: parameters, headers: updatedHeaders)
    }

    // MARK: - Authentication

    /**
     Authenticates the client with the Wing API using the configured OAuth Client ID and Client Secret.

     - Parameters:
         - completion: The callback closure that will be invoked upon receiving the response of the network request.
         - token: Optional. The token that is used to authenticate with the Wing API when performing
     authorized requests.
         - error: Optional. The error that occurred while performing the network request.

     - Throws:
         - `ClientError.unauthorized` if the OAuth Client ID and Client Secret aren't configured.
         - `NetworkError.invalidResponse` if the token could not be parsed from the response.
         - `NetworkError.unacceptableStatusCode` if an failure status code is received in the response.
     */
    public static func authenticate(completion: @escaping (_ token: String?, _ error: Error?) -> Void) {

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
