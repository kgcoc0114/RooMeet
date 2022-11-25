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

    func firebaseSignInWithApple(idToken: String, nonce: String) {
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce
        )

        auth.signIn(with: credential) { _, error in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                self.getFirebaseUserInfo()
            }
        }
    }

    func getFirebaseUserInfo() {
        let currentUser = auth.currentUser
        guard let currentUser = currentUser else {
            print("無法取得使用者資料")
            return
        }
        print(currentUser)
        let uid = currentUser.uid
        let email = currentUser.email

        print("使用者資料 uid:\(uid) email:\(String(describing: email))")
        UserDefaults.id = uid

        FirebaseService.shared.upsertUser(uid: uid, email: email) { [weak self] isNewUser, user in
            guard let `self` = self else { return }
            if isNewUser {
                let user = User(id: uid, email: email, favoriteRooms: [], reservations: [], chatRooms: [])
                self.delegate?.userService(isNewUser: isNewUser, user: user)
            } else {
                guard let user = user else { return }
                self.delegate?.userService(isNewUser: isNewUser, user: user)
            }
        }
    }

    func logOut() {
        do {
            try auth.signOut()
            print("登出中...")
            print(auth.currentUser as Any)
        } catch let signOutError as NSError {
            print("Error signing out \(signOutError.localizedDescription)")
        }
    }

    func setUserDefault() {
        UserDefaults.standard.set(auth.currentUser?.uid, forKey: "uid")
        UserDefaults.standard.set(auth.currentUser?.email, forKey: "email")
    }

    func deleteAccount(completion: @escaping ((Result<String>) -> Void)) {
        let group = DispatchGroup()
        group.enter()

        // delete data in firebase
        FirebaseService.shared.deleteAccount(userID: UserDefaults.id) { _ in
            print("deleteAccount")
            group.leave()
        }

        //  delete user in firebase
        let user = auth.currentUser
        group.enter()
        user?.delete { error in
            if error != nil {
                print(error)
            }
            group.leave()
        }

        group.enter()
        // revoke apple account
        self.revokeToken { _ in
            print("revokeToken")
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            completion(Result.success(""))
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
                    print("There was an error getting the key...\(error)")
                }
            } catch {
                print("ERROR: - Read Auth Key P8 file Error")
            }
        }

        return signedJWT
    }

    func getRefreshToken(codeString: String) {
        let clientSecret = makeJWT()

        guard let url = URL(string: "https://appleid.apple.com/auth/token?client_id=\(AppConfig.sub.value)&client_secret=\(clientSecret)&grant_type=authorization_code&code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                print("ERROR: - Can't get refresh token.")
            }

            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                print("ERROR: - Get Refresh Token Error")
                return
            }

            if let data = data {
                let response = try? JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                KeyChainService.shared.refreshToken = response?.refreshToken ?? ""
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
                print("ERROR: - Can't revoke apple account.")
                completion(Result.failure(RMError.responseError))
            }

            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                print("ERROR: - Revoke Response Error")
                completion(Result.failure(RMError.responseError))
                return
            }
            completion(Result.success("已完整刪除帳號"))
        }
        task.resume()
    }
}
