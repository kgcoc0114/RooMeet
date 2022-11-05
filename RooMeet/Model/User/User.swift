//
//  User.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
struct User: Codable {
    var id: String
    var email: String
    var birthday: Date
    var name: String
    var profilePhoto: String
    var habit: [String]?
    var hobby: [String]?
    var like: [Room]?
    var reservations: [String]?
    var chatRooms: [String]?
}

extension User {
    static let mockUser = User(
        id: "LNC9Lmn7s8LrvLOoymKv",
        email: "kgcoc0114@gmail.com",
        birthday: Date(),
        name: "kgcoc0114",
        profilePhoto:  "https://firebasestorage.googleapis.com:443/v0/b/roomeet-fbe2f.appspot.com/o/RoomImages%2F344D0652-8632-450B-8311-A46E03D68514.png?alt=media&token=1b493301-e6c8-4ecf-840d-94e9df06e31c")
}
