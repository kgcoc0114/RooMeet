//
//  RMTabBarController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

private enum Tab: String, CaseIterable {
    case home = "首頁"
    case explore = "探索"
    case chat = "聊聊"
    case profile = "個人"

    func controller() -> UIViewController {
        var controller: UIViewController
        switch self {
        case .home:
            controller = UIStoryboard.home.instantiateViewController(withIdentifier: "Home")
        case .explore:
            controller = UIStoryboard.explore.instantiateViewController(withIdentifier: "Explore")
        case .chat:
            controller = UIStoryboard.chat.instantiateViewController(withIdentifier: "Chat")
        case .profile:
            controller = UIStoryboard.profile.instantiateViewController(withIdentifier: "Profile")
        }
        controller.tabBarItem = tabBarItem()
        return controller
    }

    func tabBarItem() -> UITabBarItem {
        switch self {
        case .home:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .explore:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .chat:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )

        case .profile:
            return UITabBarItem(
                title: self.rawValue,
                image: nil,
                selectedImage: nil
            )
        }
    }
}

class RMTabBarController: UITabBarController {
    private let tabs: [Tab] = Tab.allCases

    override func viewDidLoad() {
        super.viewDidLoad()


        listenPhoneCallEvent()
    }

    func listenPhoneCallEvent() {
        let uid = UserDefaults.id

        FirebaseService.shared.fetchUserByID(userID: uid) { user, index in
            if let user = user {
                gCurrentUser = user
                print("gCurrentUser = ", gCurrentUser)
            }
        }

        FirestoreEndpoint.call.colRef
            .whereField("callee", isEqualTo: uid)
            .addSnapshotListener({ [weak self] querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                }

                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error)")
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    print(diff)
                    if diff.type == .added {
                        self?.showCallVC(document: diff.document)
                    }
                }
            })
    }

    func showCallVC(document: QueryDocumentSnapshot) {
        do {
            let call = try document.data(as: Call.self)

            if call.caller != UserDefaults.id && call.status == "offer" {
                let callViewController = CallViewController(callRoomId: call.id, callType: .answer, callerData: call.callerData, calleeData: call.calleeData)
                callViewController.modalPresentationStyle = .fullScreen
                self.present(callViewController, animated: true)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
