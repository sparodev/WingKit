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

enum ClientError: Error {
    case invalidURL
}

class Client {

    static let baseURLPath = "https://api.mywing.io/v2"
    static var oauth: OAuthCredentials? = nil

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

        return NetworkRequest(url: url, method: endpoint.method, parameters: parameters, headers: updatedHeaders)
    }

    static fileprivate func url(for endpoint: Endpoint) -> URL? {
        return URL(string: baseURLPath + endpoint.path)
    }
}
