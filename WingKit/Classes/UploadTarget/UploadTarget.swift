//
//  UploadTarget.swift
//  WingKit
//
//  Created by Matt Wahlig on 9/21/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

struct UploadTarget: Decodable {

    struct Keys {
        static let id = "id"
        static let key = "key"
        static let bucket = "bucket"
    }

    var id: String
    var key: String
    var bucket: String

    init?(from decoder: JSONDecoder) {

        guard let json = decoder.json else {
            return nil
        }

        guard let id = json[Keys.id] as? String,
            let key = json[Keys.key] as? String,
            let bucket = json[Keys.bucket] as? String else {
                return nil
        }

        self.id = id
        self.key = key
        self.bucket = bucket
    }
}
