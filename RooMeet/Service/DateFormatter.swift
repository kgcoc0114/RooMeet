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
    let currentTimestamp = Timestamp()
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

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_tw")
        return dateFormatter
    }()

    func datetimeString(date: Date) -> String {
        dateFormatter.dateFormat = "YY/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }

    func dateString(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter.string(from: date)
    }

    func dateString(dateString: String) -> Date {
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter.date(from: dateString)!
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

    func genMessageTimeString(messageTime: Timestamp) -> String {
        let currentTime = Date()

        let messageTimeComponents = Calendar.current.dateComponents(in: TimeZone.current, from: messageTime.dateValue())
        let messageTime = Date(timeIntervalSince1970: TimeInterval(messageTime.seconds))

        let diffDays = Calendar.current.dateComponents([.day], from: currentTime, to: messageTime)

        // 昨天
        let lastDateTime = currentTime.addingTimeInterval(-(24 * 60 * 60))

        let messageDateString = dateString(date: messageTime)
        let currentDateString = dateString(date: currentTime)
        let lastDateString = dateString(date: lastDateTime)

        let messageTimeString = timeString(date: messageTime)

        if messageDateString == currentDateString {
            return messageTimeString
        } else if messageDateString == lastDateString {
            return RMConstants.shared.yesterday
        }
        let days = abs(diffDays.day ?? 0)
        if days < 7 && days >= 1 {
            guard let weekday = messageTimeComponents.weekday else {
                return messageDateString
            }

            return RMWeekday.allCases[weekday - 1].descZhTw
        }
        return messageDateString
    }
}
