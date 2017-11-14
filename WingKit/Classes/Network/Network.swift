//
//  Network.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation
import AWSS3

internal typealias JSON = [String: Any]

internal struct NetworkRequest {
    var url: URL
    var acceptableStatusCodes: [Int]
    var method: HTTPMethod
    var parameters: [String: Any]?
    var headers: [String: String]?
}

internal protocol URLRequestConvertible {
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

/// The `NetworkError` enum describes domain specific errors for the `Network` class.
public enum NetworkError: Error {

    /// Indicates the response json could not be parsed.
    case invalidResponse

    /// Indicates the response's status code wasn't included in the endpoint's acceptable status codes.
    case unacceptableStatusCode(code: Int)
}

internal protocol NetworkProtocol {
    func send(request: URLRequestConvertible, completion: @escaping (JSON?, Error?) -> Void)
    func uploadFile(atFilepath filepath: String, toBucket bucket: String,
                    withKey key: String, completion: @escaping (Error?) -> Void)
}

internal class Network: NetworkProtocol {

    static var shared: NetworkProtocol = Network()

    fileprivate var defaultAcceptableStatusCodes: [Int] { return Array(200..<300) }
    fileprivate let identityPoolId = "us-east-1:af3df912-5e61-40dc-9c5e-651f7e0b3789"
    fileprivate let cognitoRegion = AWSRegionType.USEast1
    fileprivate let bucketRegion = AWSRegionType.USEast1

    internal init() {

        AWSServiceManager.default().defaultServiceConfiguration = AWSServiceConfiguration(
            region: bucketRegion,
            credentialsProvider: AWSCognitoCredentialsProvider(
                regionType: cognitoRegion,
                identityPoolId: identityPoolId
            )
        )
    }

    internal func send(request: URLRequestConvertible, completion: @escaping (JSON?, Error?) -> Void) {

            var urlRequest: URLRequest
            do {
                urlRequest = try request.asURLRequest()
            } catch {
                completion(nil, error)
                return
            }

            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in

                if let error = error {
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }

                guard let response = response else {
                    completion(nil, NetworkError.invalidResponse)
                    return
                }

                let statusCodes = (request as? NetworkRequest)?.acceptableStatusCodes ?? self.defaultAcceptableStatusCodes

                do {
                    try self.validateResponse(response, acceptableStatusCodes: statusCodes)

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

        task.resume()
    }

    internal func uploadFile(atFilepath filepath: String, toBucket bucket: String,
                    withKey key: String, completion: @escaping (Error?) -> Void) {

        let expression = AWSS3TransferUtilityUploadExpression()

        expression.progressBlock = { task, progress in
            DispatchQueue.main.async { print("Uploading test \(progress)") }
        }

        AWSS3TransferUtility.default().uploadFile(
            URL(fileURLWithPath: filepath),
            bucket: bucket, key: key,
            contentType: "audio/x-wav",
            expression: expression) { (_, error) in
                DispatchQueue.main.async {
                    completion(error)
                }
        }
    }

    fileprivate func validateResponse(_ response: URLResponse, acceptableStatusCodes: [Int]) throws {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard acceptableStatusCodes.contains(response.statusCode) else {
            throw NetworkError.unacceptableStatusCode(code: response.statusCode)
        }

        return
    }
}
