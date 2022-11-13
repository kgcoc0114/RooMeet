//
//  ProfileViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

enum Profile: CaseIterable {
    case favorite
    case reservations
    case blockade
    case logout

    var title: String {
        switch self {
        case .favorite:
            return "Favorites"
        case .reservations:
            return "Reservations"
        case .blockade:
            return "Blockade"
        case .logout:
            return "Logout"
        }
    }

    var iconImage: UIImage {
        switch self {
        case .favorite:
            return UIImage(systemName: "heart")!.withTintColor(RMConstants.shared.mainColor)
        case .reservations:
            return UIImage(systemName: "calendar")!.withTintColor(RMConstants.shared.mainColor)
        case .blockade:
            return UIImage(systemName: "nosign")!.withTintColor(RMConstants.shared.mainColor)
        case .logout:
            return UIImage(systemName: "zzz")!.withTintColor(RMConstants.shared.mainColor)
        }
    }

    var viewConroller: UIViewController {
        switch self {
        case .favorite:
            return FavoritesViewController()
        case .reservations:
            return ProfileRSVNViewController()
        case .blockade:
            return UIViewController()
        case .logout:
            return UIViewController()
        }
    }
}

class ProfileViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var editIntroButton: UIButton!
    override func viewDidLayoutSubviews() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleToFill
        profileImageView.layer.cornerRadius = 128 / 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Profile"

        tableView.delegate = self
        tableView.dataSource = self

        profileImageView.setImage(urlString: gCurrentUser.profilePhoto)

        editIntroButton.setTitle("", for: .normal)
        editIntroButton.isEnabled = false
        editButton.setTitle("", for: .normal)
        editButton.addTarget(self, action: #selector(editIntro), for: .touchUpInside)
    }


    @objc private func editIntro() {
        let introductionVC = IntroViewController(entryPage: "true", user: gCurrentUser)
        introductionVC.completion = { [self] user in
            gCurrentUser = user
            profileImageView.setImage(urlString: gCurrentUser.profilePhoto)
        }
        present(introductionVC, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Profile.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
            return UITableViewCell()
        }

        cell.profileType = Profile.allCases[indexPath.item]
        cell.configureCell()

        return cell
    }
}

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileType = Profile.allCases[indexPath.item]
        let pushVC = profileType.viewConroller
        navigationController?.pushViewController(pushVC, animated: true)
    }
}
