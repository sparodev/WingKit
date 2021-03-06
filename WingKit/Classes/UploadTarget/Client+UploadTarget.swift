//
//  Client+UploadTarget.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/27/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

internal enum UploadTargetEndpoint: Endpoint {

    case create(patientId: String, sessionId: String)

    var path: String {
        switch self {
        case .create(let patientId, let sessionId): return "/patients/\(patientId)/test-sessions/\(sessionId)/upload"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .get
        }
    }

    var acceptableStatusCodes: [Int] {
        switch self {
        case .create: return [200]
        }
    }
}

extension Client {

    internal func createUploadTarget(forTestSessionId testSessionId: String, patientId: String,
                                   completion: @escaping (UploadTarget?, Error?) -> Void) {

        guard token != nil else {
            completion(nil, ClientError.unauthorized)
            return
        }

        var request: URLRequestConvertible
        do {
            request = try self.request(for: UploadTargetEndpoint.create(patientId: patientId, sessionId: testSessionId))
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
                let target = try decoder.decode(UploadTarget.self, from: json)
                completion(target, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    internal func uploadFile(atFilepath filepath: String,
                             to uploadTarget: UploadTarget, completion: @escaping (Error?) -> Void) {

        Network.shared.uploadFile(atFilepath: filepath, toBucket: uploadTarget.bucket,
                                  withKey: uploadTarget.key, completion: completion)
    }

}
