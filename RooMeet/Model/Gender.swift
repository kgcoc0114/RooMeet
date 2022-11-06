//
//  Gender.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation

// (0: male, 1: female, 2: nonBinary, 3: all)
enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non Binary"
    case all = "All"
}

enum RoomType: String, CaseIterable {
    case studio = "套房"
    case privateRoom = "雅房"
    case entirePlace = "整層"

    var desc: String {
        switch self {
        case .studio:
            return "studio"
        case .privateRoom:
            return "privateRoom"
        case .entirePlace:
            return "entirePlace"
        }
    }
}


enum TransType: String {
    case bus = "Bus"
    case mrt = "MRT"
}
