//
//  RMTabBarController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import UIKit
private enum Tab: String, CaseIterable {
    case home = "首頁"
    case explore = "探索"
    case chat = "聊聊"
    case profile = "個人"

    func controller() -> UIViewController {
        var controller: UIViewController
        switch self {
        case .home:
            controller = UIStoryboard.home.instantiateViewController(withIdentifier: "Home")
        case .explore:
            controller = UIStoryboard.explore.instantiateViewController(withIdentifier: "Explore")
        case .chat:
            controller = UIStoryboard.chat.instantiateViewController(withIdentifier: "Chat")
        case .profile:
            controller = UIStoryboard.profile.instantiateViewController(withIdentifier: "Profile")
        }
        controller.tabBarItem = tabBarItem()
        return controller
    }

    func tabBarItem() -> UITabBarItem {
        switch self {
        case .home:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .explore:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .chat:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .profile:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )
        }
    }
}

class RMTabBarController: UITabBarController {
    private let tabs: [Tab] = Tab.allCases

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
