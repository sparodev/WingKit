//
//  Date.swift
//  Wing
//
//  Created by Matt Wahlig on 8/25/16.
//  Copyright © 2016 Sparo, Inc. All rights reserved.
//

import Foundation

extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return formatter
        }()

        static let iso8601WithMilliseconds: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return formatter
        }()

        static func dateFromString(_ dateString: String) -> Date? {
            return Formatter.iso8601.date(from: dateString)
                ?? Formatter.iso8601WithMilliseconds.date(from: dateString)
        }
    }
    var iso8601: String { return Formatter.iso8601WithMilliseconds.string(from: self) }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.Formatter.dateFromString(self)
    }
}
