//
//  Date+FITS.swift
//  Astro
//
//  Created by James Wilson on 9/7/2023.
//

import Foundation

extension Date {
    init?(fitsDate: String) {
        let formatter = DateFormatter()
        if fitsDate.firstMatch(of: /^[0-9]+\/[0-9]+\/[0-9]+$/) != nil {
            formatter.dateFormat = "d/MM/yy"
        } else if fitsDate.firstMatch(of: /\.[0-9]+$/) != nil {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: fitsDate) else {
            return nil
        }
        self = date
    }
}
