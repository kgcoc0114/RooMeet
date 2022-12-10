//
//  IntroScenario.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/7.
//

import UIKit

protocol IntroDataCell: UICollectionViewCell {
    func configure(for introScenario: IntroScenario)
}

enum IntroScenario: Hashable {
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
            guard
                let favoriteCounty = user.favoriteCounty,
                let favoriteTown = user.favoriteTown else { return "" }
            return "\(favoriteCounty)\(favoriteTown)"
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

    var dismissBtnStatus: Bool {
        switch self {
        case .create:
            return true
        case .edit:
            return false
        }
    }
}

enum IntroItem: Hashable {
    case main(IntroScenario)
    case rules(IntroScenario)

    var cellIdentifier: String {
        switch self {
        case .main:
            return IntroCell.reuseIdentifier
        case .rules:
            return ItemsCell.reuseIdentifier
        }
    }

    var introScenario: IntroScenario {
        switch self {
        case .main(let introScenario):
            return introScenario
        case .rules(let introScenario):
            return introScenario
        }
    }
}
