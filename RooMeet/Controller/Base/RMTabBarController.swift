//
//  RMTabBarController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

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
    let locationManger = LocationService.shared.locationManger

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        listenPhoneCallEvent()

        // get User Location
        locationManger.delegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.locationManger.requestLocation()
        }
    }

    func listenPhoneCallEvent() {
        let uid = UserDefaults.id

        FirestoreEndpoint.call.colRef
            .whereField("callee", isEqualTo: uid)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                }

                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(String(describing: error))")
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    if diff.type == .added {
                        self?.showCallVC(document: diff.document)
                    }
                }
            }
    }

    func showCallVC(document: QueryDocumentSnapshot) {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { user, _ in
            guard let user = user else {
                return
            }

            var blocks = user.blocks ?? []
            blocks.append(UserDefaults.id)

            do {
                let call = try document.data(as: Call.self)

                if call.caller != UserDefaults.id && call.status == "offer" && !blocks.contains(call.caller) {
                    let callViewController = CallViewController(
                        callRoomId: call.id,
                        callType: .answer,
                        callerData: call.callerData,
                        calleeData: call.calleeData
                    )
                    callViewController.modalPresentationStyle = .fullScreen
                    self.present(callViewController, animated: true)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension RMTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let viewControllers = tabBarController.viewControllers {
            if viewController == viewControllers[viewControllers.count - 1] || viewController == viewControllers[viewControllers.count - 2] {
                if AuthService.shared.isLogin() {
                    return true
                } else {
                    let loginVC = UIStoryboard.main.instantiateViewController(
                        withIdentifier: String(describing: LoginViewController.self)
                    )
                    loginVC.modalPresentationStyle = .overCurrentContext
                    self.present(loginVC, animated: false)
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - CLLocationManagerDelegate
extension RMTabBarController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            RMConstants.shared.currentPosition = location.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
