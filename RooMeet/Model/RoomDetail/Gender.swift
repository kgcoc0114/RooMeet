//
//  Gender.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation
import UIKit

// (0: male, 1: female, 2: nonBinary, 3: all)
enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non Binary"

    var image: UIImage {
        switch self {
        case .male:
            return UIImage.asset(.gender_male)
        case .female:
            return UIImage.asset(.gender_female)
        case .nonBinary:
            return UIImage.asset(.gender_non_binary)
        }
    }
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

    var index: Int {
        switch self {
        case .studio:
            return 0
        case .privateRoom:
            return 1
        case .entirePlace:
            return 2
        }
    }
}


enum TransType: String {
    case bus = "Bus"
    case mrt = "MRT"
}
