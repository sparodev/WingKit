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

/// The `DecodingError` enum describes the types of errors that can occur while decoding.
public enum DecodingError: Error {

    /// Indicates that the json was unable to be decoded into the specified type.
    case decodingFailed
}

public class JSONDecoder {

    var json: JSON?

    func decode<T: Decodable>(_ type: T.Type, from json: JSON) throws -> T {

        self.json = json

        guard let object = T(from: self) else {
            throw DecodingError.decodingFailed
        }

        return object
    }
}
