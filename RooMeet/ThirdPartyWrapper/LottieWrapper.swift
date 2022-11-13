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

    func startCallAnimate(animationView: LottieAnimationView) {
        animationView.play(fromProgress: 0, toProgress: 30, loopMode: .loop)
    }

    func endCallAnimate(animationView: LottieAnimationView) {
        animationView.stop()
    }
}
