//
//  Network.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

internal typealias JSON = [String: Any]

struct NetworkRequest {
    var url: URL
    var method: HTTPMethod
    var parameters: [String: Any]?
    var headers: [String: String]?
}

protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}

extension NetworkRequest: URLRequestConvertible {

    func asURLRequest() throws -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        if let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }

        return request
    }
}

enum NetworkError: Error {
    case invalidResponse
    case unacceptableStatusCode(code: Int)
}

protocol NetworkProtocol {
    func send(request: URLRequestConvertible, completion: @escaping (JSON?, Error?) -> Void)
    func uploadFile(atFilepath filepath: String, toBucket bucket: String,
                    withKey key: String, completion: (Error?) -> Void)
}

internal class Network: NetworkProtocol {

    static var shared: NetworkProtocol = Network()

    fileprivate var acceptableStatusCodes: [Int] { return Array(200..<300) }

    func send(request: URLRequestConvertible, completion: @escaping (JSON?, Error?) -> Void) {

            var urlRequest: URLRequest
            do {
                urlRequest = try request.asURLRequest()
            } catch {
                completion(nil, error)
                return
            }

            URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in

                if let error = error {
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }

                guard let response = response else {
                    completion(nil, NetworkError.invalidResponse)
                    return
                }

                do {
                    try self.validateResponse(response)

                    guard let data = data,
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSON else {
                            DispatchQueue.main.async { completion(nil, NetworkError.invalidResponse) }
                            return
                    }

                    DispatchQueue.main.async { completion(json, nil) }

                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            })
    }

    func uploadFile(atFilepath filepath: String, toBucket bucket: String,
                           withKey key: String, completion: (Error?) -> Void) {




    }

    fileprivate func validateResponse(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard acceptableStatusCodes.contains(response.statusCode) else {
            throw NetworkError.unacceptableStatusCode(code: response.statusCode)
        }

        return
    }
}
