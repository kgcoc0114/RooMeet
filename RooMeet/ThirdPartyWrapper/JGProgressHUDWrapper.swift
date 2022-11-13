//
//  JGProgressHUDWrapper.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import JGProgressHUD

enum HUDType {
    case success(String)
    case failure(String)
}

class RMProgressHUD {

    static let shared = RMProgressHUD()

    private init() { }

    let hud = JGProgressHUD(style: .dark)


    static func show(type: HUDType, presentVC: UIViewController) {
        switch type {
        case .success(let text):
            showSuccess(text: text, view: presentVC.view)

        case .failure(let text):
            showFailure(text: text, view: presentVC.view)
        }
    }

    static func showSuccess(text: String = "success", view: UIView) {

        if !Thread.isMainThread {
            DispatchQueue.main.async {
                showSuccess(text: text, view: view)
            }
            return
        }

        shared.hud.textLabel.text = text

        shared.hud.indicatorView = JGProgressHUDSuccessIndicatorView()

        shared.hud.show(in: view)

        shared.hud.dismiss(afterDelay: 1.5)
    }

    static func showFailure(text: String = "Failure", view: UIView) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                showFailure(text: text, view: view)
            }

            return
        }

        shared.hud.textLabel.text = text

        shared.hud.indicatorView = JGProgressHUDErrorIndicatorView()

        shared.hud.show(in: view)

        shared.hud.dismiss(afterDelay: 1.5)
    }

    static func show(view: UIView) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                show(view: view)
            }

            return
        }

        shared.hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        shared.hud.textLabel.text = "Loading"
        shared.hud.show(in: view)
    }

    static func dismiss() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                dismiss()
            }

            return
        }

        shared.hud.dismiss()
    }
}
