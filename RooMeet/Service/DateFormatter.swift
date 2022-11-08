//
//  DateFormatter.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/8.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class DateFormatter {
    static let shared = DateFormatter()

//    formatter.string(from: timeInterval)

    let formatter = DateComponentsFormatter()

    func getTimeIntervalString(startTimestamp: Timestamp, endTimestamp: Timestamp) -> String? {
        let sDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp.seconds))
        let eDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp.seconds))

        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]

        let timeInterval = eDate.timeIntervalSince(sDate)

        return formatter.string(from: timeInterval)
    }
}
