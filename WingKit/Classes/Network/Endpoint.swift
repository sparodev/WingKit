//
//  Endpoint.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

internal enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

internal protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var acceptableStatusCodes: [Int] { get }
}
