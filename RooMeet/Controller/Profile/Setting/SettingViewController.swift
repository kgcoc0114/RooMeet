//
//  SettingViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/25.
//

import UIKit
import SafariServices
import AuthenticationServices
import CryptoKit

enum SettingItem: CaseIterable {
    case privacy
    case blockade
    case delete

    var title: String {
        switch self {
        case .privacy:
            return "隱私權政策"
        case .blockade:
            return "黑名單"
        default:
            return "刪除帳號"
        }
    }

    var icon: UIImage {
        switch self {
        case .privacy:
            return UIImage.asset(.lock)
        case .delete:
            return UIImage.asset(.trash_1x)
        case .blockade:
            return UIImage.asset(.blockade)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .privacy:
            return .subTitleOrangeColor
        case .blockade:
            return .mainColor
        case .delete:
            return .subTitleRedColor
        }
    }
}

class SettingViewController: UIViewController {
    var currentNonce: String?
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Setting"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))
        configureTableView()
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(
            UINib(nibName: SettingCell.identifier, bundle: nil),
            forCellReuseIdentifier: SettingCell.identifier
        )
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

extension SettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.identifier) as? SettingCell else {
            return UITableViewCell()
        }
        cell.configureCell(data: SettingItem.allCases[indexPath.item])
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingItem.allCases.count
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let settingItem = SettingItem.allCases[indexPath.item]
        switch settingItem {
        case .privacy:
            showPrivacyPolicyPage()
        case .blockade:
            showBlockadePage()
        case .delete:
            deleteAccountAction()
        }
    }
}

extension SettingViewController: SFSafariViewControllerDelegate {
    func showPrivacyPolicyPage() {
        if let url = URL(string: RMConstants.shared.privacyPolicyURL) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        }
    }

    func showBlockadePage() {
        let pushVC = BlockViewController()
        self.hidesBottomBarWhenPushed = true
        DispatchQueue.main.async {
            self.hidesBottomBarWhenPushed = false
        }
        navigationController?.pushViewController(pushVC, animated: true)
    }
}


extension SettingViewController {
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

extension SettingViewController: ASAuthorizationControllerDelegate {
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

            if
                let authorizationCode = appleIDCredential.authorizationCode,
                let codeString = String(data: authorizationCode, encoding: .utf8) {
                AuthService.shared.getRefreshToken(codeString: codeString) { [weak self] result in
                    guard let self = self else { return }

                    switch result {
                    case .success:
                        AuthService.shared.firebaseSignInWithApple(
                            idToken: idTokenString,
                            nonce: nonce,
                            actionType: "delete"
                        ) { result in
                            switch result {
                            case .success:
                                print("SUCCESS: - Firebase Sign In With Apple")
                            case .failure(let error):
                                print("ERROR: - \(error.localizedDescription)")
                            }
                            RMProgressHUD.dismiss()
                            self.showLoginVC()
                        }
                    case .failure(let error):
                        print("ERROR: - \(error.localizedDescription)")
                        RMProgressHUD.dismiss()
                        self.showLoginVC()
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension SettingViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}


extension SettingViewController {
    private func deleteAccountAction() {
        let deleteUserAction = UIAlertAction(title: AccountString.deleteTitle.rawValue, style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            RMProgressHUD.show()

            self.signInWithApple()
        }

        presentAlertVC(
            title: AccountString.deleteTitle.rawValue,
            message: AccountString.deleteMsg.rawValue,
            mainAction: deleteUserAction,
            showDismissHUD: true,
            hasCancelAction: true
        )
    }

    private func showLoginVC() {
        DispatchQueue.main.async {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: false)
        }
    }
}
