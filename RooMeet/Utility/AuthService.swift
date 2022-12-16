//
//  AuthService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/16.
//

import FirebaseAuth
import SwiftJWT

protocol UserServiceDelegate: AnyObject {
    func userService(isNewUser: Bool, user: User)
}

class AuthService {
    static let shared = AuthService()
    var currentNonce: String?

    private var auth = Auth.auth()

    let user = UserDefaults()

    weak var delegate: UserServiceDelegate?

    func isLogin() -> Bool {
        return auth.currentUser != nil
    }

    func firebaseSignInWithApple(
        idToken: String,
        nonce: String,
        actionType: String = "signIn",
        completion: @escaping ((Result<String>) -> Void)
    ) {
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce
        )

        auth.signIn(with: credential) { [weak self] _, error in
            guard let self = self else { return }

            if let error = error {
                print(error.localizedDescription)
                completion(Result.failure(error))
            } else {
                if actionType == "delete" {
                    self.deleteAccount(credential: credential) { result in
                        completion(result)
                    }
                } else {
                    self.getFirebaseUserInfo(actionType: actionType) { result in
                        completion(result)
                    }
                }
            }
        }
    }

    func getFirebaseUserInfo(actionType: String = "signIn", completion: @escaping ((Result<String>) -> Void)) {
        let currentUser = auth.currentUser
        guard let currentUser = currentUser else {
            debugPrint("無法取得使用者資料")
            return
        }
        print(currentUser)
        let uid = currentUser.uid
        let email = currentUser.email

        UserDefaults.id = uid

        FIRUserService.shared.upsertUser(userID: uid, email: email) { [weak self] isNewUser, user in
            guard let self = self else { return }
            if isNewUser {
                let user = User(id: uid, email: email, favoriteRooms: [], reservations: [], chatRooms: [])
                self.delegate?.userService(isNewUser: isNewUser, user: user)
            } else {
                guard let user = user else { return }
                self.delegate?.userService(isNewUser: isNewUser, user: user)
            }
            completion(Result.success(""))
        }
    }

    func logOut(completion: @escaping ((Result<Bool>) -> Void)) {
        do {
            try auth.signOut()
            debugPrint("登出中...")
            completion(Result.success(true))
        } catch let signOutError as NSError {
            completion(Result.failure(signOutError))
        }
    }

    func setUserDefault() {
        UserDefaults.standard.set(auth.currentUser?.uid, forKey: "uid")
        UserDefaults.standard.set(auth.currentUser?.email, forKey: "email")
    }

    func deleteAccount(credential: OAuthCredential, completion: @escaping ((Result<String>) -> Void)) {
        let group = DispatchGroup()

        // delete data in firebase
        group.enter()
        FIRUserService.shared.deleteAccount(userID: UserDefaults.id) { _ in
            group.leave()
        }

        //  delete user in firebase
        let user = auth.currentUser

        group.enter()
        user?.delete { [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.reauthenticateFIR(credential: credential) {
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.enter()
        // revoke apple account
        self.revokeToken { _ in
            group.leave()
        }

        UserDefaults.reset()

        group.notify(queue: DispatchQueue.main) {
            completion(Result.success(""))
        }
    }

    private func reauthenticateFIR(credential: OAuthCredential, completion: @escaping (() -> Void)) {
        let user = auth.currentUser
        user?.reauthenticate(with: credential) { result, error in
            if let error = error {
                completion()
            } else {
                user?.delete { error in
                    if let error = error {
                        debugPrint(error)
                    }
                    completion()
                }
            }
        }
    }

    func makeJWT() -> String {
        var signedJWT = ""

        if let url = Bundle.main.url(forResource: AppConfig.authKeyP8.value, withExtension: "p8") {
            do {
                let data = try Data(contentsOf: url)
                let rmHeader = Header(kid: AppConfig.kid.value)

                let rmClaims = RMClaims(
                    iss: AppConfig.iss.value,
                    sub: AppConfig.sub.value,
                    exp: Date(timeIntervalSinceNow: 12000),
                    aud: AppConfig.aud.value
                )

                var jwt = JWT(header: rmHeader, claims: rmClaims)

                do {
                    let jwtSigner = JWTSigner.es256(privateKey: data)
                    signedJWT = try jwt.sign(using: jwtSigner)
                } catch {
                    debugPrint("ERROR: - Getting the key...\(error)")
                }
            } catch {
                debugPrint("ERROR: - Read Auth Key P8 file Error")
            }
        }
        return signedJWT
    }

    func getRefreshToken(codeString: String, completion: @escaping ((Result<String>) -> Void)) {
        let clientSecret = makeJWT()
        guard let url = URL(string: "https://appleid.apple.com/auth/token?client_id=\(AppConfig.sub.value)&client_secret=\(clientSecret)&grant_type=authorization_code&code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(Result.failure(error!))
            }

            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                completion(Result.failure(RMError.responseError))
                debugPrint("ERROR: - Get Refresh Token Error")
                return
            }

            if let data = data {
                let response = try? JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                KeyChainService.shared.refreshToken = response?.refreshToken ?? ""
                completion(Result.success(""))
            }
        }
        task.resume()
    }

    func revokeToken(completion: @escaping ((Result<String>) -> Void)) {
        let clientSecret = makeJWT()
        guard let refreshToken = KeyChainService.shared.refreshToken else {
            return
        }

        guard let url = URL(string: "https://appleid.apple.com/auth/revoke?client_id=\(AppConfig.sub.value)&client_secret=\(clientSecret)&token=\(refreshToken)&token_type_hint=refresh_token".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                debugPrint("ERROR: - Can't revoke apple account.")
                completion(Result.failure(RMError.responseError))
            }

            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                debugPrint("ERROR: - Revoke Response Error")
                completion(Result.failure(RMError.responseError))
                return
            }
            completion(Result.success("已完整刪除帳號"))
        }
        task.resume()
    }
}
