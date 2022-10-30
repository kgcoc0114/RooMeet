//
//  UIStoryboard+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import Foundation
import UIKit

private struct StoryboardCategory {
    static let home = "Home"
    static let explore = "Explore"
    static let chat = "Chat"
    static let profile = "Profile"
}

extension UIStoryboard {
    static var home: UIStoryboard {
        return UIStoryboard(name: StoryboardCategory.home, bundle: nil)
    }

    static var explore: UIStoryboard {
        return UIStoryboard(name: StoryboardCategory.explore, bundle: nil)
    }

    static var chat: UIStoryboard {
        return UIStoryboard(name: StoryboardCategory.chat, bundle: nil)
    }

    static var profile: UIStoryboard {
        return UIStoryboard(name: StoryboardCategory.profile, bundle: nil)
    }
}
