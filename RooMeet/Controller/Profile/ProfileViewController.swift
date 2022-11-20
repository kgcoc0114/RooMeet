//
//  ProfileViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

struct ColorSet {
    let font: UIColor
    let background: UIColor
}

enum Profile: CaseIterable {
    case favorite
    case reservations
    case post
    case blockade
    case delete
    case logout

    var title: String {
        switch self {
        case .favorite:
            return "我的收藏"
        case .reservations:
            return "預約"
        case .post:
            return "貼文"
        case .blockade:
            return "黑名單"
        case .delete:
            return "刪除帳號"
        case .logout:
            return "登出"
        }
    }

    var iconImage: UIImage {
        switch self {
        case .favorite:
            return UIImage(systemName: "heart.fill")!
        case .reservations:
            return UIImage(systemName: "calendar")!
        case .post:
            return UIImage(systemName: "house.fill")!
        case .delete:
            return UIImage(systemName: "delete.left.fill")!
        case .blockade:
            return UIImage(systemName: "nosign")!
        case .logout:
            return UIImage(systemName: "moon.zzz.fill")!
        }
    }

    var firstLineColorSet: ColorSet {
        return ColorSet(font: UIColor.mainBackgroundColor, background: UIColor.subColor)
    }

    var secondLineColorSet: ColorSet {
        return ColorSet(font: UIColor.mainDarkColor, background: UIColor.mainLightColor)
    }


    var color: ColorSet {
        switch self {
        case .favorite:
            return firstLineColorSet
        case .reservations:
            return firstLineColorSet
        case .post:
            return firstLineColorSet
        case .delete:
            return secondLineColorSet
        case .blockade:
            return secondLineColorSet
        case .logout:
            return secondLineColorSet
        }
    }

    var viewConroller: UIViewController {
        switch self {
        case .favorite:
            return FavoritesViewController(entryPage: .fav)
        case .reservations:
            return ProfileRSVNViewController()
        case .blockade:
            return UIViewController()
        case .logout:
            return UIViewController()
        case .post:
            return FavoritesViewController(entryPage: .ownPost)
        case .delete:
            return UIViewController()
        }
    }
}

class ProfileViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var userNameLabel: UILabel!
//    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var editIntroButton: UIButton!

    override func viewDidLayoutSubviews() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = (profileImageView.bounds.height * 0.25)
        editIntroButton.layer.cornerRadius = (editIntroButton.bounds.height * 0.25)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Profile"

        collectionView.register(UINib(nibName: "ProfileItemCell", bundle: nil), forCellWithReuseIdentifier: ProfileItemCell.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = configureLayout()

        collectionView.isScrollEnabled = false

        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { user, _ in
            guard let user = user else {
                return
            }
            gCurrentUser = user
            FirebaseService.shared.fetchRoomCountsOwnByUserID(userID: UserDefaults.id) { count in
                gCurrentUser.postCount = count
            }
        }

        if UserDefaults.profilePhoto != "empty" {
            profileImageView.setImage(urlString: UserDefaults.profilePhoto)
        } else {
            profileImageView.image = UIImage.asset(.profile_user)
        }

        userNameLabel.text = UserDefaults.name
        editIntroButton.setTitle("", for: .normal)
        editIntroButton.addTarget(self, action: #selector(editIntro), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { user, _ in
            guard let user = user else {
                return
            }
            gCurrentUser = user
            FirebaseService.shared.fetchRoomCountsOwnByUserID(userID: UserDefaults.id) { count in
                gCurrentUser.postCount = count
            }
        }
        collectionView.reloadData()
    }

    @objc private func editIntro() {
        let introductionVC = IntroViewController(entryType: EntryType.edit, user: gCurrentUser)
        introductionVC.completion = { [weak self] user in
            guard let self = self else { return }

            gCurrentUser = user

            if UserDefaults.profilePhoto != "empty"{
                self.profileImageView.setImage(urlString: UserDefaults.profilePhoto)
            } else {
                self.profileImageView.image = UIImage.asset(.profile_user)
            }
        }

        present(introductionVC, animated: true)
    }
}

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Profile.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileItemCell.identifier, for: indexPath) as? ProfileItemCell else {
            return UICollectionViewCell()
        }

        let profileType = Profile.allCases[indexPath.item]

        cell.profileType = profileType

        switch profileType {
        case .favorite:
            cell.configureCell(count: gCurrentUser.favoriteRooms.count)
        case .reservations:
            cell.configureCell(count: gCurrentUser.reservations.count)
        case .post:
            cell.configureCell(count: gCurrentUser.postCount ?? 0)

        case .blockade, .delete, .logout:
            cell.configureCell(count: nil)
        }
        return cell
    }
}

// layout
extension ProfileViewController {
    func configureLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.33),
            heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.33)), subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30)

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profileType = Profile.allCases[indexPath.item]
        if profileType == .logout {
            AuthService.shared.logOut()
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyBoard.instantiateViewController(
                withIdentifier: "LoginViewController"
            )
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: false)
        }

        let pushVC = profileType.viewConroller
        navigationController?.pushViewController(pushVC, animated: true)
    }
}
