//
//  DateHelper.swift
//  aba-camera
//
//  Created by Taichi Asakura on 2025/01/26.
//

import Foundation

class DateHelper {
    static func toISOString(date: Date) -> String {
        return date.formatted(.iso8601
            .year()
            .month()
            .day()
            .timeZone(separator: .omitted)
            .time(includingFractionalSeconds: true)
            .timeSeparator(.colon)
        )
    }
    
    static func fromISOString(string: String) -> Date {
        let isoDateFormatter: ISO8601DateFormatter = .init()
        isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        isoDateFormatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withDashSeparatorInDate,
            .withFractionalSeconds]
        
        return isoDateFormatter.date(from: string)!
    }
}
