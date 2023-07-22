//
//  Date+Session.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import Foundation

extension Date {
    static var _sessionDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter
    }

    func sessionDateString(in timezone: TimeZone = Calendar.current.timeZone, calendar: Calendar = Calendar.current) -> String {
        var sessionDate = self
        let components = calendar.dateComponents(in: timezone, from: self)
        if components.hour! < 12 {
            sessionDate = calendar.date(byAdding: .day, value: -1, to: sessionDate)!
        }
        let dateFormatter = Date._sessionDateFormatter
        dateFormatter.timeZone = timezone
        dateFormatter.calendar = calendar
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: sessionDate)
    }

    init?(sessionDateString: String) {
        let dateFormatter = Date._sessionDateFormatter
        if let date = dateFormatter.date(from: sessionDateString) {
            self = date
        } else {
            return nil
        }
    }
}
