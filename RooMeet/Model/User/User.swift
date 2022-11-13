//
//  User.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
struct User: Codable, Hashable {
    var id: String
    var email: String
    var gender: Int
    var birthday: Date
    var name: String
    var profilePhoto: String
    var introduction: String?
    var habit: [String]?
    var rules: [String]?
    var favorateCounty: String?
    var favorateTown: String?
    var like: [String]? = []
    var reservations: [String]?
    var chatRooms: [String]?
    var age: Int {
        return Calendar.current.dateComponents([.year], from: birthday, to: Date()).year!
    }
}

extension User {
    static let mockUser = User(
        id: "LNC9Lmn7s8LrvLOoymKv",
        email: "kgcoc0114@gmail.com",
        gender: 1,
        birthday: Date(),
        name: "kgcoc0114",
        profilePhoto:  "https://firebasestorage.googleapis.com:443/v0/b/roomeet-fbe2f.appspot.com/o/RoomImages%2F344D0652-8632-450B-8311-A46E03D68514.png?alt=media&token=1b493301-e6c8-4ecf-840d-94e9df06e31c")

    static let mockUser1 = User(
        id: "uRzWzteO70l2fI1lN5L5",
        email: "vincent@gmail.com",
        gender: 1,
        birthday: Date(),
        name: "Riley",
        profilePhoto:  "https://firebasestorage.googleapis.com:443/v0/b/roomeet-fbe2f.appspot.com/o/RoomImages%2FE0CC3BA2-F776-47F4-9CEB-D0BEC894FA9F.png?alt=media&token=2f20abc0-44fd-48d7-9a0e-28ecf671da56")
}
