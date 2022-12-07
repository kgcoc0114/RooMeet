//
//  IntroScenario.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/7.
//

import Foundation

enum IntroScenario {
    case create(user: User)
    case edit(user: User)

    var name: String {
        switch self {
        case .create:
            return ""
        case .edit(let user):
            return user.name ?? ""
        }
    }

    var birthdayString: String {
        switch self {
        case .create:
            return ""
        case .edit(let user):
            return RMDateFormatter.shared.dateString(date: user.birthday ?? Date())
        }
    }

    var gender: Int {
        switch self {
        case .create:
            return 0
        case .edit(let user):
            return user.gender ?? 0
        }
    }

    var regionString: String {
        switch self {
        case .create:
            return ""
        case .edit(let user):
            return user.favoriteCounty == nil ? "" : "\(user.favoriteCounty!)\(user.favoriteTown!)"
        }
    }

    var introduction: String {
        switch self {
        case .create:
            return ""
        case .edit(let user):
            return user.introduction ?? ""
        }
    }

    var profilePhoto: String {
        switch self {
        case .create:
            return ""
        case .edit(let user):
            return user.profilePhoto ?? ""
        }
    }

    var rules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let user):
            return user.rules ?? []
        }
    }

    var user: User? {
        switch self {
        case .create:
            return nil
        case .edit(let user):
            return user
        }
    }
}
