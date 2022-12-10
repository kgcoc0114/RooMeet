//
//  UserDefaults+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/17.
//

import Foundation

extension UserDefaults {
    @UserDefaultValue(key: "id", defaultValue: "testUser")
    static var id: String

    @UserDefaultValue(key: "gender", defaultValue: 2)
    static var gender: Int

    @UserDefaultValue(key: "birthday", defaultValue: Date())
    static var birthday: Date

    @UserDefaultValue(key: "name", defaultValue: "userName")
    static var name: String

    @UserDefaultValue(key: "profilePhoto", defaultValue: "empty")
    static var profilePhoto: String

    @UserDefaultValue(key: "favoriteCounty", defaultValue: "臺北市")
    static var favoriteCounty: String

    @UserDefaultValue(key: "favoriteTown", defaultValue: "中正區")
    static var favoriteTown: String

    @UserDefaultValue(key: "rules", defaultValue: [])
    static var rules: [String]

    static func reset() {
        id = "testUser"
        birthday = Date()
        gender = 2
        name = "User Name"
        profilePhoto = "empty"
        favoriteCounty = "臺北市"
        favoriteTown = "中正區"
        rules = []
    }

    static func update(user: User) {
        birthday = user.birthday ?? Date()
        gender = user.gender ?? 2
        name = user.name ?? "User Name"
        profilePhoto = user.profilePhoto ?? "empty"
        favoriteCounty = user.favoriteCounty ?? "臺北市"
        favoriteTown = user.favoriteTown ?? "中正區"
        rules = user.rules ?? []
    }
}
