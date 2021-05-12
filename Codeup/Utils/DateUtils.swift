//
//  DateUtils.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/27/21.
//

import Foundation

class DateUtils {
    static func convertDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: date)
    }
    
    static func convertStringToDate(isoString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        guard let date = formatter.date(from: isoString) else {
            print("Invalid date")
            return nil
        }
        
        let modifiedDate = Calendar.current.date(byAdding: .hour, value: -5, to: date)
        
        return date
    }
}
