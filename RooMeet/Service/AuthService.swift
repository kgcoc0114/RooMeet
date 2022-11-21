//
//  AuthService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/16.
//
import FirebaseAuth

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

        print("使用者資料 uid:\(uid) email:\(email)")
        UserDefaults.id = uid
        if let email = email {

        }

        FirebaseService.shared.upsertUser(uid: uid, email: email) { [weak self] isNewUser in
            guard let `self` = self else { return }
            if isNewUser {
                let user = User(id: uid, email: email, favoriteRooms: [], reservations: [], chatRooms: [])
                self.delegate?.userService(isNewUser: isNewUser, user: user)
            } else {
                self.delegate?.userService(isNewUser: isNewUser, user: gCurrentUser)
            }
        }
    }

    func logOut() {
        do {
            try auth.signOut()
            print("登出中...")
            print(auth.currentUser)
        } catch let signOutError as NSError {
            print("Error signing out \(signOutError.localizedDescription)")
        }
    }

    func setUserDefault() {
        UserDefaults.standard.set(auth.currentUser?.uid, forKey: "uid")
        UserDefaults.standard.set(auth.currentUser?.email, forKey: "email")
    }
}

