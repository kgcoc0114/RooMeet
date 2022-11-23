//
//  User.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Codable, Hashable {
    var id: String
    var email: String?
    var gender: Int?
    var birthday: Date?
    var name: String?
    var profilePhoto: String?
    var introduction: String?
    var habit: [String]?
    var rules: [String]?
    var favoriteCounty: String?
    var favoriteTown: String?
    var favoriteRooms: [FavoriteRoom] = []
    var reservations: [String] = []
    var chatRooms: [String]? = []
    var blocks: [String]? = []

    var postCount: Int?

    var age: Int {
        return Calendar.current.dateComponents([.year], from: birthday!, to: Date()).year!
    }

    var favoriteRoomIDs: [String] {
        return favoriteRooms.map { data in
            data.roomID
        }
    }

    var dictionary: [String: Any] {
        return [
            "id": id,
            "email": email as Any,
            "gender": gender as Any,
            "birthday": birthday as Any,
            "name": name as Any,
            "profilePhoto": profilePhoto as Any,
            "introduction": introduction as Any,
            "habit": habit as Any,
            "favoriteCounty": favoriteCounty as Any,
            "favoriteTown": favoriteTown as Any,
            "favoriteRooms": favoriteRooms as Any,
            "reservations": reservations as Any,
            "chatRooms": chatRooms as Any
        ]
    }
}

struct FavoriteRoom: Codable, Hashable {
    var roomID: String
    var createdTime: Timestamp
    var room: Room?
    var dictionary: [String: Any] {
        return [
            "roomID": roomID,
            "createdTime": createdTime
        ]
    }
}
