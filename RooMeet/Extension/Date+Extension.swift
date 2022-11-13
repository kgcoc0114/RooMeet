//
//  Date+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//
import Foundation

enum Weekday: CaseIterable {
    case sun
    case mon
    case tue
    case wed
    case thu
    case fri
    case sat

    var description: String {
        switch self {
        case .sun:
            return "SUN"
        case .mon:
            return "MON"
        case .tue:
            return "TUE"
        case .wed:
            return "WED"
        case .thu:
            return "THU"
        case .fri:
            return "FRI"
        case .sat:
            return "SAT"
        }
    }
}

extension Date {
    func getDaysInWeek(days: Int) -> [DateComponents] {
        var dates: [DateComponents] = []
        for day in 0...(days - 1) {
            let date = Calendar.current.date(byAdding: .day, value: day, to: self)
            let dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: date!)
            dates.append(dateComponents)
        }

        return dates
    }
}

class RMDater: DateFormatter {

//    static let shared = RMDater()

    var dateFormatter = DateFormatter()

    func genDateString() {

    }
}
