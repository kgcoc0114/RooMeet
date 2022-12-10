//
//  UIViewController+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/10.
//

import UIKit

extension UIViewController {
    func backToRoot(completion: (() -> Void)? = nil) {
        if presentingViewController != nil {
            let superVC = presentingViewController
            dismiss(animated: false, completion: nil)
            superVC?.backToRoot(completion: completion)
            return
        }

        if let tabbarVC = self as? UITabBarController {
            tabbarVC.selectedViewController?.backToRoot(completion: completion)
            return
        }

        if let navigateVC = self as? UINavigationController {
            navigateVC.popToRootViewController(animated: false)
        }

        completion?()
    }
}
