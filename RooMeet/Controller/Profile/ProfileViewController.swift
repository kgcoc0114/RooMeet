//
//  ProfileViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import SafariServices

struct ColorSet {
    let font: UIColor
    let background: UIColor
}

enum Profile: CaseIterable {
    case favorite
    case reservations
    case post
    case furniture
    case setting
    case signOut

    var title: String {
        switch self {
        case .favorite:
            return "我的收藏"
        case .reservations:
            return "預約"
        case .post:
            return "貼文"
        case .furniture:
            return "家具清單"
        case .setting:
            return "帳號設定"
        case .signOut:
            return "登出"
        }
    }

    var iconImage: UIImage {
        switch self {
        case .favorite:
            return UIImage.asset(.heart_white)
        case .reservations:
            return UIImage.asset(.calendar)
        case .post:
            return UIImage.asset(.home_white)
        case .setting:
            return UIImage.asset(.setting)
        case .furniture:
            return UIImage.asset(.chair)
        case .signOut:
            return UIImage.asset(.sign_out)
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
            return ColorSet(font: .white, background: UIColor.mainColor)
        case .reservations:
            return ColorSet(font: .white, background: UIColor.subTitleOrangeColor)
        case .post:
            return ColorSet(font: .white, background: UIColor.subTitleRedColor)
        case .setting:
            return secondLineColorSet
        case .furniture:
            return secondLineColorSet
        case .signOut:
            return secondLineColorSet
        }
    }

    var viewConroller: UIViewController {
        switch self {
        case .favorite:
            return FavoritesViewController(entryPage: .fav)
        case .reservations:
            return ProfileRSVNViewController()
        case .furniture:
            return FurnitureListViewController()
        case .signOut:
            return UIViewController()
        case .post:
            return FavoritesViewController(entryPage: .ownPost)
        case .setting:
            return SettingViewController()
        }
    }
}

class ProfileViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(editIntro)
            )
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.isUserInteractionEnabled = true
            profileImageView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            userNameLabel.font = UIFont.regularSubTitle()
            userNameLabel.textColor = UIColor.mainDarkColor
        }
    }

    @IBOutlet weak var editIntroButton: UIButton! {
        didSet {
            editIntroButton.setImage(UIImage.asset(.refresh), for: .normal)
        }
    }

    private var user: User? {
        didSet {
            profileImageView.loadImage(self.user?.profilePhoto, placeHolder: UIImage.asset(.roomeet))
            userNameLabel.text = self.user?.name
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Profile"

        collectionView.register(
            UINib(nibName: "ProfileItemCell", bundle: nil),
            forCellWithReuseIdentifier: ProfileItemCell.identifier
        )

        DispatchQueue.global(qos: .background).async {
            ReservationService.shared.deleteExpiredReservations()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = configureLayout()
        collectionView.isScrollEnabled = false

        editIntroButton.setTitle("", for: .normal)
        editIntroButton.addTarget(self, action: #selector(editIntro), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard
                let self = self,
                let user = user else {
                return
            }

            self.user = user
        }

        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        editIntroButton.layer.cornerRadius = (editIntroButton.bounds.height * 0.25)
    }

    @objc private func editIntro() {
        guard let user = user else {
            return
        }

        let introductionVC = IntroViewController(IntroScenario.edit(user: user))
        introductionVC.completion = { [weak self] _ in
            guard let self = self else { return }
            self.profileImageView.loadImage(UserDefaults.profilePhoto, placeHolder: UIImage.asset(.roomeet))
        }

        introductionVC.modalPresentationStyle = .fullScreen
        present(introductionVC, animated: true)
    }

    @IBAction func showPrivacyPolicyPage(_ sender: Any) {
        if let url = URL(string: RMConstants.shared.privacyPolicyURL) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        }
    }
}

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Profile.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProfileItemCell.identifier,
            for: indexPath) as? ProfileItemCell else {
            return UICollectionViewCell()
        }

        let profileType = Profile.allCases[indexPath.item]

        cell.profileType = profileType
        cell.configureCell()
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profileType = Profile.allCases[indexPath.item]
        switch profileType {
        case .favorite, .reservations, .post, .setting, .furniture:
            let pushVC = profileType.viewConroller
            navigationController?.pushViewController(pushVC, animated: true)
        case .signOut:
            AuthService.shared.logOut { [weak self] _ in
                guard let self = self else { return }
                self.showLoginVC()
            }
        }
    }

    private func showLoginVC() {
        DispatchQueue.main.async {
            self.navigationController?.tabBarController?.selectedIndex = 0
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: false)
        }
    }
}
