//
//  DateFormatter.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/8.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class RMDateFormatter {
    static let shared = RMDateFormatter()

//    formatter.string(from: timeInterval)

    let formatter = DateComponentsFormatter()

    func getTimeIntervalString(
        startTimestamp: Timestamp,
        endTimestamp: Timestamp,
        allowUnits: NSCalendar.Unit = [.hour, .minute, .second]
    ) -> String? {
        let sDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp.seconds))
        let eDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp.seconds))

        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = allowUnits

        let timeInterval = eDate.timeIntervalSince(sDate)

        return formatter.string(from: timeInterval)
    }

    let dateFormatter = DateFormatter()

    func datetimeString(date: Date) -> String {
        dateFormatter.dateFormat = "YY/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }

    func dateString(date: Date) -> String {
        dateFormatter.dateFormat = "YY/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }

    func timeString(date: Date) -> String {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }

    func datetimeWithLocaleString(date: Date, dateFormat: String) -> String {
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "zh_tw")
        return dateFormatter.string(from: date)
    }
}
