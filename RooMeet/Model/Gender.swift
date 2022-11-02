//
//  Gender.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation

// (0: male, 1: female, 2: nonBinary, 3: all)
enum Gender: String {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non Binary"
    case all = "All"
}

enum RoomType: String {
    case male = "Male"
    case female = "Female"
//    case nonBinary = "Non Binary"\
}


enum TransType: String {
    case bus = "Bus"
    case mrt = "MRT"
}
