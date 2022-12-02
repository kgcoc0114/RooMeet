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

    @IBOutlet weak var dismissButton: UIButton! {
        didSet {
            dismissButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var subnitButton: UIButton! {
        didSet {
            subnitButton.setTitle("Save", for: .normal)
            subnitButton.backgroundColor = UIColor.mainColor
            subnitButton.tintColor = UIColor.mainBackgroundColor
            subnitButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    enum Section: CaseIterable {
        case main
        case rules
    }

    enum Item: Hashable {
        case main(User)
        case rules(User)
    }

    let imagePickerController = UIImagePickerController()

    var user: User?

    var rules: [String] = RMConstants.shared.roomHighLights
        + RMConstants.shared.roomCookingRules
        + RMConstants.shared.roomElevatorRules
        + RMConstants.shared.roomBathroomRules
        + RMConstants.shared.roomPetsRules

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
        self.user = user ?? User(id: UserDefaults.id)
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
        dismissButton.isHidden = entryType == .new
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        fetchUser()
        updateDataSource()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "IntroCell", bundle: nil),
            forCellWithReuseIdentifier: IntroCell.identifier)
        collectionView.register(
            UINib(nibName: "ItemsCell", bundle: nil),
            forCellWithReuseIdentifier: ItemsCell.reuseIdentifier)

        dataSource = IntroDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }
            switch item {
            case .main(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: IntroCell.identifier,
                    for: indexPath) as? IntroCell else {
                    return UICollectionViewCell()
                }
                cell.delegate = self

                let profilePhoto = UserDefaults.profilePhoto
                if profilePhoto != "empty" {
                    cell.imageView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
                } else {
                    cell.imageView.image = UIImage.asset(.roomeet)
                }

                let edit = self.entryType == .edit && self.user != nil
                cell.configureCell(edit: edit, data: data)
                return cell
            case .rules:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ItemsCell.reuseIdentifier,
                    for: indexPath) as? ItemsCell else {
                    return UICollectionViewCell()
                }

                if let tmpRemoveIndex = self.rules.firstIndex(of: "可議") {
                    self.rules.remove(at: tmpRemoveIndex)
                }

                cell.configureTagView(
                    ruleType: "要求",
                    tags: self.rules,
                    selectedTags: self.user?.rules ?? [],
                    mainColor: UIColor.mainColor,
                    lightColor: UIColor.mainLightColor,
                    mainLightBackgroundColor: UIColor.mainBackgroundColor,
                    enableTagSelection: true
                )
                cell.delegate = self
                return cell
            }
        }

        collectionView.collectionViewLayout = configureLayout()
    }

    private func fetchUser() {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else { return }
            self.user = user
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        RMProgressHUD.show()
        guard let profileImage = profileImage else {
            saveData(url: nil)
            return
        }
        uploadImages(image: profileImage)
    }

    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true)
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

        if let profilePhoto = user.profilePhoto {
            UserDefaults.profilePhoto = profilePhoto
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
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 16, trailing: 20)
                return section
            case .rules:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(30))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(30))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20)
                return section
            }
        }
    }
}

// MARK: - Snapshot
extension IntroViewController {
    private func updateDataSource() {
        guard let user = user else { return }
        var newSnapshot = IntroSnapshot()
        newSnapshot.appendSections([.main, .rules])
        newSnapshot.appendItems([.main(user)], toSection: .main)
        newSnapshot.appendItems([.rules(user)], toSection: .rules)
        dataSource.apply(newSnapshot)
    }
}

extension IntroViewController: IntroCellDelegate {
    func passData(cell: IntroCell, data: User) {
        user = data
    }

    func showRegionPickerView(cell: IntroCell) {
        cell.regionTextField.resignFirstResponder()
        let regionPickerVC = LocationPickerViewController()
        regionPickerVC.modalPresentationStyle = .overCurrentContext

        regionPickerVC.completion = { [self] county, town in
            cell.county = county
            cell.town = town
            self.user?.favoriteCounty = county
            self.user?.favoriteTown = town
        }
        present(regionPickerVC, animated: false)
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
        if let pickedImage = info[.originalImage] as? UIImage {
            guard let cell = profileImageCell else {
                return
            }

            cell.imageView.image = pickedImage
            profileImage = pickedImage
        }

        picker.dismiss(animated: true)
    }

    private func uploadImages(image: UIImage) {
        DispatchQueue.global().async {
            let uniqueString = NSUUID().uuidString
            let storageRef = Storage.storage().reference(withPath: "Profile").child("\(uniqueString).png")
            if let uploadData = image.scale(scaleFactor: 0.1).jpegData(compressionQuality: 0.1) {
                storageRef.putData(uploadData) { [weak self] _, error in
                    if let error = error {
                        // TODO: Error Handle
                        print("Error: \(error.localizedDescription)")
                        return
                    }

                    storageRef.downloadURL { [weak self] url, _ in
                        guard let downloadURL = url else {
                            return
                        }
                        print("Photo Url: \(downloadURL)")
                        print(Thread.current)
                        self?.saveData(url: downloadURL)
                    }
                }
            }
        }
    }


    private func saveData(url: URL?) {
        guard var user = user else { return }

        let userRef = FirestoreEndpoint.user.colRef.document(user.id)

        var updateData: [AnyHashable: Any]


        updateData = [
            "rules": user.rules as Any,
            "introduction": user.introduction as Any,
            "name": user.name as Any,
            "gender": user.gender as Any,
            "birthday": user.birthday as Any,
            "favoriteCounty": user.favoriteCounty as Any,
            "favoriteTown": user.favoriteTown as Any
        ]

        if user.favoriteRooms.isEmpty {
            updateData["favoriteRooms"] = []
        }

        if user.reservations.isEmpty {
            updateData["reservations"] = []
        }

        if let url = url {
            updateData["profilePhoto"] = url.absoluteString
            user.profilePhoto = url.absoluteString
        }

        userRef.updateData(updateData)
        updateUserDefault(user: user)
        completion?(user)
        if entryType == .new {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let RMTabBarVC = storyBoard.instantiateViewController(
                withIdentifier: "RMTabBarController") as? RMTabBarController
            else {
                return
            }
            UIApplication.shared.windows.first?.rootViewController = RMTabBarVC
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            RMProgressHUD.showSuccess()
        } else {
            backToRoot(completion: nil)
            RMProgressHUD.showSuccess()
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

extension IntroViewController: ItemsCellDelegate {
    func itemsCell(cell: ItemsCell, selectedTags: [String]) {
        user?.rules = selectedTags
    }
}
