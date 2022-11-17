//
//  IntroViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseStorage

class IntroViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    enum Section: CaseIterable {
        case main
        case rules
    }

    enum Item: Hashable {
        case main(User)
        case rules(String)
    }

    let imagePickerController = UIImagePickerController()

    var user: User?
    var rules: [String] = [] {
        didSet {
            updateDataSource()
        }
    }

    var completion: ((User) -> Void)?

    private var profileImageCell: IntroCell?
    private var profileImage: UIImage?
    private var favoriteCounty: String?
    private var favoriteTown: String?
    private var entryType: EntryType?

    typealias IntroDataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias IntroSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: IntroDataSource!

    init(entryType: EntryType, user: User? = nil) {
        super.init(nibName: "IntroViewController", bundle: nil)
        self.entryType = entryType
        self.user = user
        print("====", user?.gender)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) {[weak self] user, _ in
            guard let self = self else { return }
            self.user = user
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDataSource()
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "IntroCell", bundle: nil),
            forCellWithReuseIdentifier: IntroCell.identifier)
        collectionView.register(
            UINib(nibName: "TagCell", bundle: nil),
            forCellWithReuseIdentifier: TagCell.identifier)
        dataSource = IntroDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .main(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: IntroCell.identifier,
                    for: indexPath) as? IntroCell else {
                    return UICollectionViewCell()
                }
                cell.delegate = self
                if let profilePhoto = UserDefaults.standard.string(forKey: "profilePhoto") {
                    cell.imageView.setImage(urlString: profilePhoto)
                } else {
                    cell.imageView.image = UIImage.asset(.profile_user)
                }
                cell.configureCell(data: data)
                return cell
            case .rules(let rule):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.identifier, for: indexPath) as? TagCell else {
                    return UICollectionViewCell()
                }

                cell.configureCell(data: rule)
                return cell
            }
        }

        collectionView.collectionViewLayout = configureLayout()
    }

    private func fetchUser() {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { user, _ in
            self.user = user
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        guard let profileImage = profileImage else {
            saveData(url: nil)
            return
        }
        uploadImages(image: profileImage)
    }

    func updateUserDefault(user: User) {
        if let rules = user.rules {
            UserDefaults.rules = rules
        }

        if let name = user.name {
            UserDefaults.name = name
        }

        if let birthday = user.birthday {
            UserDefaults.birthday = birthday
        }

        if let favoriteCounty = user.favoriteCounty {
            UserDefaults.favoriteCounty = favoriteCounty
        }

        if let favoriteTown = user.favoriteTown {
            UserDefaults.favoriteTown = favoriteTown
        }
    }
}

// MARK: - Layout
extension IntroViewController {
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch Section.allCases[sectionIndex] {
            case .main:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(30))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(30))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                return section
            case .rules:
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(44), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(44), heightDimension: .absolute(50))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                return section
            }
        }
    }
}

// MARK: - Snapshot
extension IntroViewController {
    private func updateDataSource() {
        var newSnapshot = IntroSnapshot()
        newSnapshot.appendSections([.main, .rules])
        newSnapshot.appendItems([.main(user!)], toSection: .main)
        newSnapshot.appendItems(rules.map({ Item.rules($0) }), toSection: .rules)
        dataSource.apply(newSnapshot)
    }
}

extension IntroViewController: IntroCellDelegate {
    func passData(cell: IntroCell, data: User) {
        user = data
    }

    func showRulePickerView(cell: IntroCell) {
        cell.ruleTextField.endEditing(true)
        let mutlipleChooseVC = MutlipleChooseController()
        mutlipleChooseVC.setup(pageType: .rule, selectedOptions: [])

        mutlipleChooseVC.completion = { [self] selectedItem in
            if selectedItem.isEmpty {
                user?.rules = selectedItem
            }
        }
        present(mutlipleChooseVC, animated: true)
    }

    func showRegionPickerView(cell: IntroCell) {
        cell.regionTextField.resignFirstResponder()
        let regionPickerVC = RegionPickerViewController()
        regionPickerVC.completion = { [self] county, town in
            cell.county = county
            cell.town = town
            self.user?.favoriteCounty = county
            self.user?.favoriteTown = town
        }
        present(regionPickerVC, animated: true)
    }

    func didClickImageView(_ cell: IntroCell) {
        profileImageCell = cell
        imagePickerController.delegate = self

        let imagePickerAlertController = UIAlertController(
            title: "上傳圖片",
            message: "請選擇要上傳的圖片",
            preferredStyle: .actionSheet
        )

        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.imagePickerController.sourceType = .photoLibrary
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }

        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)

        present(imagePickerAlertController, animated: true, completion: nil)
    }
}


extension IntroViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
//        var selectedImageFromPicker: UIImage

        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {
            guard let cell = profileImageCell else {
                return
            }

            cell.imageView.image = pickedImage
//            selectedImageFromPicker = pickedImage
            profileImage = pickedImage
        }

        picker.dismiss(animated: true)
    }

    private func uploadImages(image: UIImage) {
        DispatchQueue.global().async {
            let uniqueString = NSUUID().uuidString
            let storageRef = Storage.storage().reference(withPath: "Profile").child("\(uniqueString).png")
            if let uploadData = image.scale(scaleFactor: 0.1).jpegData(compressionQuality: 0.1) {
                storageRef.putData(uploadData, completion: {[weak self] data, error in
                    if let error = error {
                        // TODO: Error Handle
                        print("Error: \(error.localizedDescription)")
                        return
                    }

                    storageRef.downloadURL { [weak self] (url, error) in
                        guard let downloadURL = url else {
                            return
                        }
                        print("Photo Url: \(downloadURL)")
                        print(Thread.current)
                        self?.saveData(url: downloadURL)
                    }
                })
            }
        }
    }


    private func saveData(url: URL?) {
        guard var user = user else { return }

        let userRef = FirestoreEndpoint.user.colRef.document(user.id)

        var updateData: [AnyHashable: Any]


        updateData = [
            "rules": user.rules as Any,
            "name": user.name as Any,
            "gender": user.gender as Any,
            "birthday": user.birthday as Any,
            "favoriteCounty": user.favoriteCounty as Any,
            "favoriteTown": user.favoriteTown as Any
        ]

        if let url = url {
            updateData["profilePhoto"] = url.absoluteString
            user.profilePhoto = url.absoluteString
        }

        userRef.updateData(updateData)
        completion?(user)
        updateUserDefault(user: user)
        if entryType == .new {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let RMTabBarVC = storyBoard.instantiateViewController(withIdentifier: "RMTabBarController") as? RMTabBarController else {
                return
            }
            UIApplication.shared.windows.first?.rootViewController = RMTabBarVC
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        } else {
            backToRoot(completion: nil)
        }
    }
}

extension UIViewController {
    func backToRoot(completion: (() -> Void)? = nil) {
        if presentingViewController != nil {
            let superVC = presentingViewController
            dismiss(animated: false, completion: nil)
            superVC?.backToRoot(completion: completion)
            return
        }

        if let tabbarVC = self as? UITabBarController {
            tabbarVC.selectedViewController?.backToRoot(completion: completion)
            return
        }

        if let navigateVC = self as? UINavigationController {
            navigateVC.popToRootViewController(animated: false)
        }

        completion?()
    }
}
