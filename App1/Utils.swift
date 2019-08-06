//
//  Utils.swift
//  App1
//
//  Created by John Grese on 8/2/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

class Utils {
    static func ISO8601Timestamp() -> String {
        return ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: NSDate().timeIntervalSince1970))
    }

    static func ISO8601StringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return dateFormatter.string(from: date).appending("Z")
    }

    static func getTimestampComponentString() -> String {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let min = calendar.component(.minute, from: date)
        let sec = calendar.component(.second, from: date)

        return [String(year),
                String(month),
                String(day),
                String(hour),
                String(min),
                String(sec)].joined(separator: ",")
    }
}
