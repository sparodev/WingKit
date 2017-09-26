//
//  Codable.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/22/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

protocol Decodable {
    init?(from decoder: JSONDecoder)
}

enum DecodingError: Error {
    case decodingFailed
}

class JSONDecoder {

    var json: JSON?

    func decode<T: Decodable>(_ type: T.Type, from json: JSON) throws -> T {

        self.json = json

        guard let object = T(from: self) else {
            throw DecodingError.decodingFailed
        }

        return object
    }
}
