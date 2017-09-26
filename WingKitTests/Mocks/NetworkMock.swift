//
//  NetworkMock.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import Foundation

class NetworkMock: NetworkProtocol {

    var sendRequestStub: ((_ request: URLRequestConvertible, _ completion: (JSON?, Error?) -> Void) -> Void)?
    func send(request: URLRequestConvertible, completion: @escaping (JSON?, Error?) -> Void) {
        sendRequestStub?(request, completion)
    }

    var uploadFileStub: ((_ filepath: String, _ bucket: String, _ key: String, _ completion: (Error?) -> Void) -> Void)?
    func uploadFile(atFilepath filepath: String, toBucket bucket: String,
                    withKey key: String, completion: (Error?) -> Void) {
        uploadFileStub?(filepath, bucket, key, completion)
    }
}
