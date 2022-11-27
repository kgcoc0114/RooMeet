//
//  LottieWrapper.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/13.
//

import Foundation
import Lottie

class RMLottie {
    static let shared = RMLottie()

    lazy var callAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "CallWaitingView")

        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    lazy var loginAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "Roommates")

        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    lazy var reservationAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "Reservation")

        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    func startAnimate(animationView: LottieAnimationView) {
        animationView.play()
    }

    func startLoopAnimate(animationView: LottieAnimationView, fromProgress: CGFloat = 0, toProgress: CGFloat = 30) {
        animationView.play(fromProgress: fromProgress, toProgress: toProgress, loopMode: .loop)
    }

    func stopLoopAnimate(animationView: LottieAnimationView) {
        animationView.stop()
    }

    func startCallAnimate(animationView: LottieAnimationView) {
        animationView.play(fromProgress: 0, toProgress: 30, loopMode: .loop)
    }

    func endCallAnimate(animationView: LottieAnimationView) {
        animationView.stop()
    }
}
