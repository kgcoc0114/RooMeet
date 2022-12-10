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

        var contentInsets: NSDirectionalEdgeInsets {
            switch self {
            case .main:
                return NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 16, trailing: 20)
            case .rules:
                return NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20)
            }
        }
    }

    lazy var imagePicker: ImagePickerManager = {
        return ImagePickerManager(presentationController: self)
    }()

    var user: User

    var completion: ((User) -> Void)?

    private var profileImageCell: IntroCell?
    private var profileImage: UIImage?
    private var profileImageURL: String?

    private var favoriteCounty: String?
    private var favoriteTown: String?

    private let scenario: IntroScenario

    typealias IntroDataSource = UICollectionViewDiffableDataSource<Section, IntroItem>
    typealias IntroSnapshot = NSDiffableDataSourceSnapshot<Section, IntroItem>
    private var dataSource: IntroDataSource!

    init(_ scenario: IntroScenario) {
        self.scenario = scenario
        self.user = scenario.user ?? User(id: UserDefaults.id)
        super.init(nibName: String(describing: IntroViewController.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        dismissButton.isHidden = scenario.dismissBtnStatus
        imagePicker.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        updateDataSource()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func configureCollectionView() {
        collectionView.registerCellWithNib(reuseIdentifier: IntroCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: ItemsCell.reuseIdentifier, bundle: nil)

        collectionView.collectionViewLayout = configureLayout()

        dataSource = IntroDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: item.cellIdentifier,
                for: indexPath) as? IntroDataCell
            else {
                return UICollectionViewCell()
            }

            cell.configure(for: item.introScenario)

            switch item {
            case .main:
                (cell as? IntroCell)?.delegate = self
            case .rules:
                (cell as? ItemsCell)?.delegate = self
            }
            return cell
        }
    }

    private func fetchUser() {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self, let user = user  else { return }
            self.user = user
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        RMProgressHUD.show()
        guard let profileImage = profileImage else {
            saveData(url: nil)
            return
        }

        uploadImages(image: profileImage) { [weak self] profileImageURL in
            guard
                let self = self,
                let profileImageURL = profileImageURL
            else {
                RMProgressHUD.showFailure(text: "傳送圖片出現問題")
                return
            }

            self.saveData(url: profileImageURL)
        }
    }

    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - Layout
extension IntroViewController {
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(30))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(30))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = Section.allCases[sectionIndex].contentInsets
            return section
        }
    }
}

// MARK: - Snapshot
extension IntroViewController {
    private func updateDataSource() {
        var newSnapshot = IntroSnapshot()
        newSnapshot.appendSections([.main, .rules])
        newSnapshot.appendItems([.main(scenario)], toSection: .main)
        newSnapshot.appendItems([.rules(scenario)], toSection: .rules)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - Intro Data Delegate
extension IntroViewController: IntroCellDelegate {
    func passData(cell: IntroCell, data: User) {
        user = data
    }

    func showRegionPickerView(cell: IntroCell) {
        cell.regionTextField.resignFirstResponder()
        let regionPickerVC = LocationPickerViewController()
        regionPickerVC.modalPresentationStyle = .overCurrentContext

        regionPickerVC.completion = { [weak self] county, town in
            guard let self = self else { return }
            cell.county = county
            cell.town = town
            self.user.favoriteCounty = county
            self.user.favoriteTown = town
        }
        present(regionPickerVC, animated: false)
    }

    func didClickImageView(_ cell: IntroCell) {
        profileImageCell = cell
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imagePicker.present(from: cell)
        }
    }
}

// MARK: - Profile Image Picker Delegate
extension IntroViewController: ImagePickerManagerDelegate {
    func imagePickerController(didSelect: UIImage?) {
        guard let image = didSelect else { return }
        profileImageCell?.imageView.image = image
        profileImage = image
    }
}

// MARK: - Save Data
extension IntroViewController {
    private func uploadImages(image: UIImage, completion: @escaping ((URL?) -> Void)) {
        FIRStorageService.shared.uploadImage(image: image, path: FIRStorageEndpoint.profile.path) { imageURL, _ in
            guard
                let imageURL = imageURL else {
                completion(nil)
                return
            }
            completion(imageURL)
        }
    }

    private func saveData(url: URL?) {
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

        UserDefaults.update(user: user)

        completion?(user)

        switch scenario {
        case .create:
            guard let RMTabBarVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: RMTabBarController.self)
            ) as? RMTabBarController
            else {
                return
            }
            UIApplication.shared.windows.first?.rootViewController = RMTabBarVC
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            RMProgressHUD.showSuccess()
        case .edit:
            backToRoot(completion: nil)
            RMProgressHUD.showSuccess()
        }
    }
}

// MARK: - Tag Delegate
extension IntroViewController: ItemsCellDelegate {
    func itemsCell(cell: ItemsCell, selectedTags: [String]) {
        user.rules = selectedTags
    }
}
