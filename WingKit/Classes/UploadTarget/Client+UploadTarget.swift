//
//  Client+UploadTarget.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/27/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

enum UploadTargetEndpoint: Endpoint {

    case create(sessionId: String)

    var path: String {
        switch self {
        case .create(let sessionId): return "/patients/5yEwdO6MVR8ZA/test-sessions/\(sessionId)/upload"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .get
        }
    }
}

extension Client {

    static func createUploadTarget(forTestSessionId testSessionId: String,
                                   completion: @escaping (UploadTarget?, Error?) -> Void) {

        var request: URLRequestConvertible
        do {
            request = try self.request(for: UploadTargetEndpoint.create(sessionId: testSessionId))
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

    static func uploadFile(atFilepath filepath: String, to uploadTarget: UploadTarget, completion: (Error?) -> Void) {

        Network.shared.uploadFile(atFilepath: filepath, toBucket: uploadTarget.bucket,
                                  withKey: uploadTarget.key, completion: completion)
    }

}
