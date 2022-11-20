//
//  LoginViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/16.
//

import UIKit
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController {
    var currentNonce: String?
    lazy var loginAnimationView =  RMLottie.shared.loginAnimationView

    @IBOutlet weak var animationView: UIView!

    @IBOutlet weak var signInWithAppleButtonView: UIView! {
        didSet {
            signInWithAppleButtonView.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAnimationView()
        let authAppleIDButton = ASAuthorizationAppleIDButton()
        authAppleIDButton.addTarget(self, action: #selector(pressSignInWithApple), for: .touchUpInside)

        signInWithAppleButtonView.addSubview(authAppleIDButton)

        NSLayoutConstraint.activate([
            signInWithAppleButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authAppleIDButton.centerXAnchor.constraint(equalTo: signInWithAppleButtonView.centerXAnchor),
            authAppleIDButton.centerYAnchor.constraint(equalTo: signInWithAppleButtonView.centerYAnchor),
            authAppleIDButton.widthAnchor.constraint(equalTo: signInWithAppleButtonView.widthAnchor, multiplier: 1),
            authAppleIDButton.heightAnchor.constraint(equalTo: signInWithAppleButtonView.heightAnchor, multiplier: 1)
        ])

        AuthService.shared.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RMLottie.shared.startLoopAnimate(animationView: loginAnimationView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RMLottie.shared.stopLoopAnimate(animationView: loginAnimationView)
    }

    private func configureAnimationView() {
        animationView.addSubview(loginAnimationView)

        NSLayoutConstraint.activate([
            loginAnimationView.widthAnchor.constraint(equalTo: animationView.widthAnchor),
            loginAnimationView.heightAnchor.constraint(equalTo: animationView.heightAnchor),
            loginAnimationView.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            loginAnimationView.centerYAnchor.constraint(equalTo: animationView.centerYAnchor)
        ])
    }

    @objc func pressSignInWithApple() {
        signInWithApple()
    }
}


extension LoginViewController {
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

        guard let currentNonce = currentNonce else {
            return
        }

        let authAppleIDRequest: ASAuthorizationAppleIDRequest = ASAuthorizationAppleIDProvider().createRequest()
        authAppleIDRequest.requestedScopes = [.fullName, .email]
        authAppleIDRequest.nonce = sha256(currentNonce)

        let controller = ASAuthorizationController(
            authorizationRequests: [authAppleIDRequest]
        )

        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }
        .joined()

        return hashString
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            AuthService.shared.firebaseSignInWithApple(
                idToken: idTokenString,
                nonce: nonce
            )
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}


extension LoginViewController: UserServiceDelegate {
    func userService(isNewUser: Bool, user: User) {
        if isNewUser {
            let profileVC = IntroViewController(entryType: EntryType.new, user: user)
            present(profileVC, animated: true)
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let RMTabBarVC = storyBoard.instantiateViewController(
                withIdentifier: "RMTabBarController"
            ) as? RMTabBarController else {
                return
            }
            UIApplication.shared.windows.first?.rootViewController = RMTabBarVC
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
}
