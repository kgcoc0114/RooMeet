//
//  Room.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation

struct Room: Codable {
    var roomID: String
    var userID: String
    var createdTime: TimeInterval
    var modifiedTime: TimeInterval
    var title: String
    var roomImages: [URL]
    var rooms: [RoomSpec]
    var roommateGender: Int // (0: male, 1: female, 2: nonBinary, 3: all)
    var rules: [String]
    var publicAmenities: [String]
    var address: Address
    var currentLivingInfo: CurrentLivingInfo
    var billInfo: BillInfo
    var lease: Int
    var moveInDate: Date
    var otherDescriction: String
    var status: String
    var isDeleted: Bool
}

struct RoomSpec: Codable {
    let roomType: [Int]
    let price: Int
    let space: Double
    let people: Int
    let amenities: [String]
}

struct CurrentLivingInfo: Codable {
    let number: Int
    let descriction: String
}

struct Address: Codable {
    let city: String
    let county: String
    let address: String
    let lat: Double
    let long: Double
    let transportation: [Transportation]
}

struct Transportation: Codable {
    let transType: Int // (0: 公車站, 1: 捷運站）
    let distance: Double
    let site: String
}

struct BillInfo: Codable {
    let water: BillDetail
    let electricity: BillDetail
    let cable: BillDetail
    let internet: BillDetail
    let management: BillDetail
}

struct BillDetail: Codable {
    let paid: Bool
    let fee: Double
}
