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
    private var roomSpecList: [RoomSpec] = [RoomSpec()]
    var roomHighLights: [String] = []
    var roomGenderRules: [String] = []
    var roomPetsRules: [String] = []
    var roomElevatorRules: [String] = []
    var roomCookingRules: [String] = []
    var roomFeatures: [String] = []
    var roomBathroomRules: [String] = []
    var featureSelection: [String] = []

    var billInfo: BillInfo?

    lazy var imagePickerController = UIImagePickerController()

    var postBasicData: PostBasicData?

    var waitForUpdateImageCell: PostImageCell?

    var roomImagesUrl: [URL] = []
    var oriRoomImagesUrl: [URL] = []
    var checkImages: [Bool] = [false, false, false]
    var roomImages: [UIImage] = []

    var otherDescriction: String?
    var latitude: Double?
    var longitude: Double?
    var postalCode: String?
    var createdTime = Timestamp()
    var isDeleted = false
    var room: Room?

    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.setTitle("Add Post", for: .normal)
            submitButton.backgroundColor = UIColor.mainColor
            submitButton.tintColor = UIColor.mainBackgroundColor
            submitButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.collectionViewLayout = configureLayout()

            collectionView.registerCellWithNib(reuseIdentifier: PostBasicCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: RoomSpecCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: OtherFeeCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: PostImageCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: RulesCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: ItemsCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: OtherFeeHeaderCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: FeeDetailCell.reuseIdentifier, bundle: nil)
        }
    }

    var entryType: EntryType = .new

    init(entryType: EntryType, data: Room?) {
        super.init(nibName: "PostViewController", bundle: nil)

        self.entryType = entryType
        self.room = data
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.keyboardDismissMode = .interactive
        navigationItem.title = "新增物件貼文"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        if entryType == .edit {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage.asset(.trash).withRenderingMode(.alwaysOriginal),
                style: .plain,
                target: self,
                action: #selector(deletePostAction))
        }

        if let room = room {
            configureData(data: room)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func configureData(data: Room) {
        if entryType == .edit {
            roomSpecList = data.rooms
            roomHighLights = data.roomHighLights
            roomGenderRules = data.roomGenderRules
            roomPetsRules = data.roomPetsRules
            roomElevatorRules = data.roomElevatorRules
            roomCookingRules = data.roomCookingRules
            roomFeatures = data.roomFeatures
            roomBathroomRules = data.roomBathroomRules
            featureSelection = data.roomFeatures
            billInfo = data.billInfo
            postBasicData = PostBasicData(
                title: data.title,
                county: data.county,
                town: data.town,
                address: data.address,
                room: data.room,
                parlor: data.parlor,
                leaseMonth: data.leaseMonth,
                movinDate: data.movinDate,
                gender: nil
            )
            oriRoomImagesUrl = data.roomImages
            roomImagesUrl = data.roomImages
            otherDescriction = data.otherDescriction
            latitude = data.lat
            longitude = data.long
            postalCode = data.postalCode
            createdTime = data.createdTime

            data.roomImages.forEach { url in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let imageData = try? Data(contentsOf: url) {
                        if let loadedImage = UIImage(data: imageData) {
                            self.roomImages.append(loadedImage)
                        } else {
                            self.roomImages.append(UIImage.asset(.add))
                        }
                    }
                }
            }
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        guard let postBasicData = postBasicData else {
            showAlert()
            return
        }

        if postBasicData.title == nil || postBasicData.county == nil || postBasicData.movinDate == nil ||
            roomSpecList.isEmpty {
            showAlert()
        } else {
            if roomImages.isEmpty {
                room?.roomImages = []
                saveData()
            } else {
                uploadImages(images: roomImages)
            }
        }
    }

    @objc private func deletePostAction() {
        let alertController = UIAlertController(title: "刪除貼文", message: "確定要刪除貼文嗎？", preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: "確定刪除", style: .destructive) { [unowned self] _ in
            RMProgressHUD.show()
            guard
                let room = room,
                let roomID = room.roomID else {
                return
            }

            FirebaseService.shared.deletePost(roomID: roomID)
            RMProgressHUD.dismiss()
            self.navigationController?.popViewController(animated: true)
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            alertController.dismiss(animated: true)
        }

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    private func showAlert() {
        let alertController = UIAlertController(title: "新增貼文", message: "標題、地區與最快可搬入時間為必填欄位", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "好的", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: false)
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

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch PostSection.allCases[indexPath.section] {
        case .basic:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostBasicCell.reuseIdentifier,
                for: indexPath) as? PostBasicCell else {
                fatalError("PostBasicCell Error")
            }
            if entryType == .edit {
                cell.configureCell(data: postBasicData)
            }
            cell.delegate = self
            return cell
        case .roomSpec:
            return makeRoomSpecCell(collectionView: collectionView, indexPath: indexPath)
        case .images:
            return makePostImageCell(collectionView: collectionView, indexPath: indexPath)
        case .feeHeader:
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: OtherFeeHeaderCell.reuseIdentifier,
                    for: indexPath) as? OtherFeeHeaderCell,
                let tag = PostSection.allCases.firstIndex(of: .feeHeader)
                else {
                fatalError("OtherFeeHeaderCell Error")
            }

            cell.editAction.tag = tag
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
                fatalError("OtherFeeHeaderCell Error")
            }

            let section = PostSection.allCases[indexPath.section]
            let title = section.title
            var selectedTags: [String] = []

            switch section {
            case .highLight:
                selectedTags = roomHighLights
            case .gender:
                selectedTags = roomGenderRules
            case .pet:
                selectedTags = roomPetsRules
            case .elevator:
                selectedTags = roomElevatorRules
            case .cooking:
                selectedTags = roomCookingRules
            case .bathroom:
                selectedTags = roomBathroomRules
            case .features:
                selectedTags = roomFeatures
            default:
                break
            }

            cell.configureTagView(
                ruleType: title,
                tags: PostSection.allCases[indexPath.section].tags,
                selectedTags: selectedTags,
                mainColor: UIColor.mainColor,
                lightColor: UIColor.mainBackgroundColor,
                mainLightBackgroundColor: .white,
                enableTagSelection: true
            )
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
                let self = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }
            let roomSpec = RoomSpec()
            self.roomSpecList.insert(roomSpec, at: indexPath.item + 1)
            self.collectionView.reloadData()
        }

        cell.delectColumnAction = { [weak self] cell in
            guard
                let self = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }

            self.roomSpecList.remove(at: indexPath.item)
            self.collectionView.reloadData()
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
        print(indexPath.item, roomImages.count)
        if entryType == .new {
            if roomImages.count - 1 >= indexPath.item {
                cell.imageView.image = roomImages[indexPath.item]
            } else {
                cell.imageView.image = UIImage.asset(.add)
            }
        } else {
            if let room = room,
                room.roomImages.count - 1 >= indexPath.item {
                if roomImages.count - 1 >= indexPath.item {
                    cell.imageView.image = roomImages[indexPath.item]
                } else {
                    cell.imageView.loadImage(
                        room.roomImages[indexPath.item].absoluteString,
                        placeHolder: UIImage.asset(.add)
                    )
                }
            } else {
                cell.imageView.image = UIImage.asset(.add)
            }
        }
        cell.delegate = self
        return cell
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

extension PostViewController: UICollectionViewDelegate {
    @objc func showMultiChoosePage(_ sender: UIButton) {
        let postSection = PostSection.allCases[sender.tag]
        switch postSection {
        case .feeHeader:
            var editFeeVC: EditFeeController

            editFeeVC = EditFeeController(entryType: entryType, data: billInfo)

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
                    widthDimension: .fractionalWidth(0.33),
                    heightDimension: .absolute(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20)
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
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                return section
            default:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(1))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                return section
            }
        }
    }
}

extension PostViewController: PostBasicCellDelegate {
    func passData(cell: PostBasicCell, data: PostBasicData) {
        postBasicData = data
        if
            let postBasicData = postBasicData,
            let county = postBasicData.county,
            let town = postBasicData.town,
            let address = postBasicData.address {
            LocationService.shared.getCoordinates(
                fullAddress: "\(county)\(town)\(address)") { [weak self] location in
                    guard let self = self else { return }
                    self.latitude = location.latitude
                    self.longitude = location.longitude
            }
        }
    }

    func showRegionPickerView(cell: PostBasicCell) {
        cell.regionSelectView.resignFirstResponder()
        cell.endEditing(true)
        let regionPickerVC = LocationPickerViewController()
        regionPickerVC.modalPresentationStyle = .overCurrentContext
        // FIXME:
        regionPickerVC.completion = { county, town in
            cell.county = county
            cell.town = town
        }
        regionPickerVC.modalPresentationStyle = .overCurrentContext
        present(regionPickerVC, animated: false)
    }
}

extension PostViewController: RoomSpecCellDelegate {
    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        roomSpecList[indexPath.item] = data
    }
}

extension PostViewController: PostImageCellDelegate {
    func didClickImageView(_ cell: PostImageCell) {
        waitForUpdateImageCell = cell
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
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { _ in
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

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {
            waitForUpdateImageCell?.imageView.image = pickedImage
            guard let cell = self.waitForUpdateImageCell else {
                return
            }
            self.insertRoomImages(cell: cell, image: pickedImage)
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
            roomImages[indexPath.item] = image
        }
        print(roomImages)
    }

    private func uploadImages(images: [UIImage]) {
        RMProgressHUD.show()
        let group = DispatchGroup()

        roomImagesUrl = []

        images.forEach { image in
            group.enter()
            var uploadData: Data?

            let uniqueString = NSUUID().uuidString

            let imageSize = image.getSizeIn(.kilobyte)
            if imageSize > RMConstants.shared.compressSizeGap {
                let factor = RMConstants.shared.compressSizeGap / imageSize
                uploadData = image.jpegData(compressionQuality: factor)
            } else {
                uploadData = image.pngData()
            }

            let storageRef = Storage.storage().reference(withPath: "RoomImages").child("\(uniqueString).png")

            if let uploadData = uploadData {
                storageRef.putData(uploadData) { [weak self] _, error in
                    if let error = error {
                        // TODO: Error Handle
                        print("Error: \(error.localizedDescription)")
                        return
                    }

                    storageRef.downloadURL { [weak self] url, _ in
                        guard let self = self else { return }
                        guard let downloadURL = url else {
                            return
                        }
                        self.roomImagesUrl.append(downloadURL)
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            self.room?.roomImages = self.roomImagesUrl
            self.saveData()
        }
    }


    private func saveData() {
        guard let postBasicData = postBasicData else {
            return
        }

        var inputRoom = Room(
            userID: UserDefaults.id,
            createdTime: createdTime,
            modifiedTime: Timestamp(),
            title: postBasicData.title ?? "房間出租",
            roomImages: roomImagesUrl,
            rooms: roomSpecList,
            roomFeatures: roomFeatures,
            roomPetsRules: roomPetsRules,
            roomHighLights: roomHighLights,
            roomGenderRules: roomGenderRules,
            roomCookingRules: roomCookingRules,
            roomElevatorRules: roomElevatorRules,
            roomBathroomRules: roomBathroomRules,
            town: postBasicData.town ?? "中正區",
            county: postBasicData.county ?? "臺北市",
            address: postBasicData.address ?? "",
            lat: latitude,
            long: longitude,
            billInfo: billInfo,
            leaseMonth: postBasicData.leaseMonth ?? 0,
            room: postBasicData.room ?? 0,
            parlor: postBasicData.parlor ?? 0,
            movinDate: postBasicData.movinDate ?? Date(),
            isDeleted: isDeleted
        )

        inputRoom.roomMinPrice = inputRoom.getRoomMinPrice()

        if entryType == .new {
            FirebaseService.shared.insertRoom(room: inputRoom) { error in
                RMProgressHUD.dismiss()

                if error != nil {
                    RMProgressHUD.showFailure()
                } else {
                    RMProgressHUD.showSuccess()
                }
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if let room = room,
                let roomID = room.roomID {
                FirebaseService.shared.updateRoomInfo(roomID: roomID, room: inputRoom) { error in
                    RMProgressHUD.dismiss()

                    if error != nil {
                        RMProgressHUD.showFailure()
                    } else {
                        RMProgressHUD.showSuccess()
                    }
                    self.navigationController?.popViewController(animated: true)
                }
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
            self.roomElevatorRules = selectedTags
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

extension Double {
    public func roundedTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded()
    }
}
