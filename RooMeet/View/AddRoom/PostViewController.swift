//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

enum PostSection: CaseIterable {
    case basic
    case roomSpec
    case highLight
    case gender
    case pet
    case elevator
    case cooking
    case bathroom
    case features
    case feeHeader
    case feeDetail
    case images

    var title: String {
        switch self {
        case .highLight:
            return "亮點"
        case .gender:
            return "租客性別"
        case .pet:
            return "寵物"
        case .elevator:
            return "電梯"
        case .cooking:
            return "開伙"
        case .features:
            return "設施"
        case .bathroom:
            return "衛浴"
        default:
            return ""
        }
    }

    var tags: [String] {
        switch self {
        case .highLight:
            return RMConstants.shared.roomHighLights
        case .gender:
            return RMConstants.shared.roomGenderRules
        case .pet:
            return RMConstants.shared.roomPetsRules
        case .elevator:
            return RMConstants.shared.roomElevatorRules
        case .cooking:
            return RMConstants.shared.roomCookingRules
        case .features:
            return RMConstants.shared.roomFeatures
        case .bathroom:
            return RMConstants.shared.roomBathroomRules
        default:
            return []
        }
    }
}

class PostViewController: UIViewController {
    private var roomSpecList: [RoomSpec] = [RoomSpec()] {
        didSet {
            collectionView.reloadData()
        }
    }

    var roomHighLights: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var roomGenderRules: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var roomPetsRules: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var roomElevatorRules: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var roomCookingRules: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var roomFeatures: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var roomBathroomRules: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var featureSelection: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var billInfo: BillInfo? {
        didSet {
            collectionView.reloadData()
        }
    }

    var postBasicData: PostBasicData?

    var waitForUpdateImageCell: PostImageCell?

    var roomImagesUrl: [URL] = []
    var roomImages: [UIImage] = []

    var otherDescriction: String?
    var latitude: Double?
    var longitude: Double?
    var postalCode: String?

    var roommateGender: Int?
    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.setTitle("Add Post", for: .normal)
            submitButton.backgroundColor = RMConstants.shared.mainColor
            submitButton.tintColor = RMConstants.shared.mainLightColor
            submitButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.collectionViewLayout = configureLayout()
            collectionView.register(
                UINib(nibName: PostBasicCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: PostBasicCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: RoomSpecCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomSpecCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: OtherFeeCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: OtherFeeCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: PostImageCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: PostImageCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: RulesCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RulesCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: ItemsCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: ItemsCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: RulesHeaderCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RulesHeaderCell.reuseIdentifier
            )
            collectionView.register(
                UINib(nibName: FeeDetailCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: FeeDetailCell.reuseIdentifier
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.keyboardDismissMode = .interactive
        navigationItem.title = "Add Room Post"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func submitAction(_ sender: Any) {
        if roomImages.isEmpty {
            saveData(url: nil)
        } else {
            uploadImages(images: roomImages)
        }
    }
}

extension PostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItems: Int
        switch PostSection.allCases[section] {
        case .roomSpec:
            numberOfItems = roomSpecList.count
        case .basic, .feeHeader, .feeDetail, .gender, .pet, .elevator, .cooking, .features, .bathroom, .highLight:
            numberOfItems = 1
        case .images:
            numberOfItems = 3
        }
        return numberOfItems
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        PostSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch PostSection.allCases[indexPath.section] {
        case .basic:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostBasicCell.reuseIdentifier,
                for: indexPath) as? PostBasicCell else {
                fatalError("PostBasicCell Error")
            }
            cell.delegate = self
            return cell
        case .roomSpec:
            return makeRoomSpecCell(collectionView: collectionView, indexPath: indexPath)
        case .images:
            return makePostImageCell(collectionView: collectionView, indexPath: indexPath)
        case .feeHeader:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RulesHeaderCell.reuseIdentifier,
                for: indexPath) as? RulesHeaderCell else {
                fatalError("RulesHeaderCell Error")
            }
            cell.editAction.tag = PostSection.allCases.firstIndex(of: .feeHeader)!
            cell.editAction.addTarget(self, action: #selector(showMultiChoosePage), for: .touchUpInside)
            cell.titleLabel.text = "其他費用"
            return cell
        case .feeDetail:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeeDetailCell.reuseIdentifier,
                for: indexPath) as? FeeDetailCell else {
                fatalError("FeeDetailCell Error")
            }
            cell.completion = { [unowned self] otherDesc in
                self.otherDescriction = otherDesc
            }
            return cell
        case .highLight, .gender, .pet, .elevator, .cooking, .features, .bathroom:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ItemsCell.reuseIdentifier,
                for: indexPath) as? ItemsCell else {
                fatalError("RulesHeaderCell Error")
            }
            let title = PostSection.allCases[indexPath.section].title
            cell.configureTagView(
                ruleType: title,
                tags: PostSection.allCases[indexPath.section].tags,
                mainColor: RMConstants.shared.mainColor,
                lightColor: RMConstants.shared.mainLightBackgroundColor,
                mainLightBackgroundColor: .white)
            cell.delegate = self
            return cell
        }
    }

    private func makeRoomSpecCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RoomSpecCell.reuseIdentifier,
            for: indexPath
        ) as? RoomSpecCell else {
            fatalError("RoomSpecCell Error")
        }

        cell.delegate = self
        cell.configureLayout(roomSpec: roomSpecList[indexPath.item], indexPath: indexPath)

        cell.addColumnAction = { [weak self] cell in
            guard
                let `self` = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }
            let roomSpec = RoomSpec()
            self.roomSpecList.insert(roomSpec, at: indexPath.item + 1)
            print(self.roomSpecList)
        }

        cell.delectColumnAction = { [weak self] cell in
            guard
                let `self` = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }

            self.roomSpecList.remove(at: indexPath.item)
            print(self.roomSpecList)
        }
        return cell
    }

    private func makePostImageCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PostImageCell.reuseIdentifier,
            for: indexPath
        ) as? PostImageCell else {
            fatalError("PostImageCell Error")
        }
        cell.delegate = self
        return cell
    }
}

extension PostViewController: UICollectionViewDelegate {
    @objc func showMultiChoosePage(_ sender: UIButton) {
        var presentPage: UIViewController
        let postSection = PostSection.allCases[sender.tag]
        switch postSection {
        case .feeHeader:
            let editFeeVC = EditFeeController()
            editFeeVC.completion = { [weak self] billInfo in
                self?.billInfo = billInfo
            }
            editFeeVC.modalPresentationStyle = .overCurrentContext
            present(editFeeVC, animated: true)
        default:
            break
        }
    }
}

extension PostViewController {
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch PostSection.allCases[sectionIndex] {
            case .images:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.3),
                    heightDimension: .fractionalWidth(0.25))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(0.25))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section
            case .roomSpec:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(120))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section

            default:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(100))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section
            }
        }
    }
}

extension PostViewController: PostBasicCellDelegate {
    func passData(cell: PostBasicCell, data: PostBasicData) {
        postBasicData = data
        if let county = postBasicData?.county,
            let town = postBasicData?.town {
            postalCode = LocationService.shared.postalCodeList?.filter({ postal in
                postal.city == county && postal.area == town
            })[0].zip
            if let address = postBasicData?.address, !address.isEmpty {
                LocationService.shared.getCoordinates(
                    fullAddress: "\(county)\(town)\(address)") {
                        [weak self] location in
                        guard let `self` = self else { return }
                        self.latitude = location.latitude
                        self.longitude = location.longitude
                        print("\(location.latitude),\(location.longitude)")
                    }
            }
        }
    }

    func showRegionPickerView(cell: PostBasicCell) {
        cell.regionSelectView.resignFirstResponder()
        let regionPickerVC = RegionPickerViewController()
        regionPickerVC.completion = { county, town in
            cell.county = county
            cell.town = town
        }
        present(regionPickerVC, animated: true)
    }
}

extension PostViewController: RoomSpecCellDelegate {
    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        roomSpecList[indexPath.item] = data
        print(roomSpecList)
    }
}

extension PostViewController: PostImageCellDelegate {
    func didClickImageView(_ cell: PostImageCell) {
        waitForUpdateImageCell = cell
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self

        let imagePickerAlertController = UIAlertController(
            title: "上傳圖片",
            message: "請選擇要上傳的圖片",
            preferredStyle: .actionSheet
        )

        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }

        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
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

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        var selectedImageFromPicker: UIImage?

        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {
            waitForUpdateImageCell?.imageView.image = pickedImage
            selectedImageFromPicker = pickedImage
            self.insertRoomImages(cell: (self.waitForUpdateImageCell)!, image: pickedImage)
        }

        picker.dismiss(animated: true)
    }

    private func insertRoomImages(cell: UICollectionViewCell, image: UIImage) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }

        if roomImages.count - 1 < indexPath.item {
            roomImages.append(image)
        } else {
            roomImages.insert(image, at: indexPath.item)
        }
    }

    private func uploadImages(images: [UIImage]) {
        //        ProgressHUD.showProgress(0.4)

        DispatchQueue.global().async {
            images.forEach { image in
                
                let uniqueString = NSUUID().uuidString
                let storageRef = Storage.storage().reference(withPath: "RoomImages").child("\(uniqueString).png")
                if let uploadData = image.scale(scaleFactor: 0.1).jpegData(compressionQuality: 0.1) {
                    print("===",uploadData)
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
    }


    private func saveData(url: URL?) {
        print(Thread.current)
        if let url = url {
            roomImagesUrl.append(url)
        }
        if roomImagesUrl.count == roomImages.count {
            let docRef = Firestore.firestore().collection("Room").document()
            print("docRef")
            var room = Room(roomID: docRef.documentID,
                            userID: UserDefaults.id,
                            createdTime: Timestamp(),
                            modifiedTime: Timestamp(),
                            title: (postBasicData?.title)!,
                            roomImages: roomImagesUrl,
                            rooms: roomSpecList,
                            roomFeatures: roomFeatures,
                            roomPetsRules: roomPetsRules,
                            roomHighLights: roomHighLights,
                            roomGenderRules: roomGenderRules,
                            roomCookingRules: roomCookingRules,
                            roomElevatorRules: roomElevatorRules,
                            roomBathroomRules: roomBathroomRules,
                            town: (postBasicData?.town)!,
                            county: (postBasicData?.county)!,
                            address: (postBasicData?.address)!,
                            lat: latitude,
                            long: longitude,
                            postalCode: postalCode,
                            billInfo: billInfo,
                            leaseMonth: (postBasicData?.leaseMonth) ?? 12,
                            movinDate: (postBasicData?.movinDate)!,
                            otherDescriction: otherDescriction,
                            isDeleted: false)
            room.roomMinPrice = room.getRoomMinPrice()

            do {
                try docRef.setData(from: room, completion: { error in
                    if let _ = error {
                        RMProgressHUD.showFailure(view: self.view)
                    } else {
                        RMProgressHUD.showSuccess(view: self.view)
                    }
                })
                self.navigationController?.popViewController(animated: true)
            } catch {
                print("error")
            }
        }
    }
}

extension PostViewController: ItemsCellDelegate {
    func itemsCell(cell: ItemsCell, selectedTags: [String]) {
        switch cell.ruleType {
        case "亮點":
            roomHighLights = selectedTags
        case "租客性別":
            roomGenderRules = selectedTags
        case "寵物":
            roomPetsRules = selectedTags
        case "電梯":
            roomElevatorRules = selectedTags
        case "開伙":
            roomCookingRules = selectedTags
        case "設施":
            roomFeatures = selectedTags
        case "衛浴":
            roomBathroomRules = selectedTags
        default:
            break
        }
    }
}
