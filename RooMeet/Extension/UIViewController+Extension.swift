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

    func presentAlertVC(title: String, message: String, mainAction: UIAlertAction, showDismissHUD: Bool = false, hasCancelAction: Bool) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(mainAction)

        if hasCancelAction {
            let cancelAction = UIAlertAction(title: PostVCString.cancel.rawValue, style: .cancel) { _ in
                if showDismissHUD {
                    RMProgressHUD.dismiss()
                }
                alertController.dismiss(animated: true)
            }
            alertController.addAction(cancelAction)
        }

        present(alertController, animated: true)
    }
}

struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: ((UIAlertAction) -> Void)?
}
