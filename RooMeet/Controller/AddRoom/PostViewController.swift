//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit
import FirebaseFirestore

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

    var otherDescriction: String?
    var latitude: Double?
    var longitude: Double?
    var postalCode: String?
    var createdTime = Timestamp()
    var isDeleted = false
    var room: Room?

    lazy var imagePicker: ImagePickerManager = {
        let imagePicker = ImagePickerManager(presentationController: self)
        imagePicker.delegate = self
        return imagePicker
    }()

    var roomImagesUrl: [URL] = []
    var oriRoomImagesUrl: [URL] = []
    var roomImages: [UIImage] = [
        UIImage.asset(.add),
        UIImage.asset(.add),
        UIImage.asset(.add)
    ]

    var roomImagesStatus = [false, false, false]

    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.setTitle(entryType.title + PostVCString.submit.rawValue, for: .normal)
            submitButton.backgroundColor = UIColor.mainColor
            submitButton.tintColor = UIColor.mainBackgroundColor
            submitButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.registerCellWithNib(reuseIdentifier: PostBasicCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: RoomSpecCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: OtherFeeCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: PostImageCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: RulesCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: ItemsCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: OtherFeeHeaderCell.reuseIdentifier, bundle: nil)
            collectionView.registerCellWithNib(reuseIdentifier: FeeDetailCell.reuseIdentifier, bundle: nil)

            collectionView.collectionViewLayout = configureLayout()
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.keyboardDismissMode = .interactive
        }
    }

    var entryType: EntryType = .new

    init(entryType: EntryType, data: Room?) {
        super.init(nibName: "PostViewController", bundle: nil)

        self.entryType = entryType

        guard let data = data else {
            return
        }

        self.room = data
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self

        navigationItem.title = entryType.title + PostVCString.title.rawValue

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        if entryType == .edit {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage.asset(.trash).withRenderingMode(.alwaysOriginal),
                style: .plain,
                target: self,
                action: #selector(deletePostAction))
            if let room = room {
                configureData(data: room)
            }
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
                movinDate: data.movinDate
            )
            oriRoomImagesUrl = data.roomImages
            roomImagesUrl = data.roomImages
            otherDescriction = data.otherDescriction
            latitude = data.lat
            longitude = data.long
            postalCode = data.postalCode
            createdTime = data.createdTime
        }
    }

    func isSavable() -> (Bool, String) {
        var isSavable = true
        var message = PostVCString.addMessage.rawValue

        guard let postBasicData = self.postBasicData else {
            return (false, message)
        }

        if postBasicData.title == nil || postBasicData.county == nil || postBasicData.movinDate == nil ||
            self.roomSpecList.isEmpty {
            return (false, message)
        }

        for roomSpec in roomSpecList {
            if roomSpec.price == nil || roomSpec.space == nil {
                isSavable = false
                message = PostVCString.roomSpecAlertMessage.rawValue
                break
            }
        }

        return (isSavable, message)
    }

    @IBAction func submitAction(_ sender: Any) {
        let isSavable = isSavable()
        if isSavable.0 {
            RMProgressHUD.show()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                if self.roomImages.isEmpty {
                    self.room?.roomImages = []
                    self.saveData()
                } else {
                    self.uploadImages(images: self.roomImages)
                }
            }
        } else {
            showAlert(message: isSavable.1)
        }
    }

    @objc private func deletePostAction() {
        let deleteAction = UIAlertAction(
            title: PostVCString.deleteActionTitle.rawValue,
            style: .destructive
        ) { [weak self] _ in
            RMProgressHUD.show()
            guard
                let self = self,
                let roomID = self.room?.roomID else {
                return
            }

            FIRRoomService.shared.deletePost(roomID: roomID)
            RMProgressHUD.dismiss()
            self.navigationController?.popViewController(animated: true)
        }

        self.presentAlertVC(
            title: PostVCString.delete.rawValue,
            message: PostVCString.deleteMessage.rawValue,
            mainAction: deleteAction,
            hasCancelAction: true
        )
    }

    private func showAlert(message: String = PostVCString.addMessage.rawValue) {
        DispatchQueue.main.async { [weak self] in
            RMProgressHUD.dismiss()
            guard let self = self else { return }
            let alertAction = UIAlertAction(title: PostVCString.confirm.rawValue, style: .default)

            self.presentAlertVC(
                title: PostVCString.add.rawValue,
                message: message,
                mainAction: alertAction,
                hasCancelAction: false
            )
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
            let postSection = PostSection.allCases[indexPath.section]

            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: postSection.cellIdentifier,
                    for: indexPath) as? PostCell
            else {
                fatalError("OtherFeeHeaderCell Error")
            }

            cell.configure(container: PostDataContainer(indexPath: indexPath))
            (cell as? OtherFeeHeaderCell)?.editAction.addTarget(
                self,
                action: #selector(showMultiChoosePage),
                for: .touchUpInside
            )
            return cell
        case .feeDetail:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeeDetailCell.reuseIdentifier,
                for: indexPath) as? FeeDetailCell else {
                fatalError("FeeDetailCell Error")
            }
            cell.completion = { [weak self] otherDesc in
                guard let self = self else { return }
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
        let postSection = PostSection.allCases[indexPath.section]

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: postSection.cellIdentifier,
            for: indexPath
        ) as? PostCell else {
            fatalError("RoomSpecCell Error")
        }
        cell.configure(container: PostDataContainer(roomImages: nil, indexPath: indexPath, roomSpecList: roomSpecList))
        (cell as? RoomSpecCell)?.delegate = self
        return cell
    }

    private func makePostImageCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let postSection = PostSection.allCases[indexPath.section]
        print(indexPath.item, postSection)
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: postSection.cellIdentifier,
            for: indexPath
        ) as? PostCell else {
            fatalError("PostImageCell Error")
        }
        cell.configure(container: PostDataContainer(
            roomImages: roomImages,
            roomImagesURL: roomImagesUrl,
            indexPath: indexPath,
            roomSpecList: nil
        ))
        (cell as? PostImageCell)?.delegate = self
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
            return PostSection.allCases[sectionIndex].sectionLayout
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

        regionPickerVC.completion = { county, town in
            cell.county = county
            cell.town = town
        }
        regionPickerVC.modalPresentationStyle = .overCurrentContext
        present(regionPickerVC, animated: false)
    }
}

extension PostViewController: RoomSpecCellDelegate {
    func addSpec(_ cell: RoomSpecCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        roomSpecList.insert(RoomSpec(), at: indexPath.item + 1)
        collectionView.reloadData()
    }

    func deleteSpec(_ cell: RoomSpecCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        roomSpecList.remove(at: indexPath.item)
        collectionView.reloadData()
    }

    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        if roomSpecList.count > indexPath.item {
            roomSpecList[indexPath.item] = data
        }
    }
}

extension PostViewController: PostImageCellDelegate {
    func didClickImageView(_ cell: PostImageCell) {
        waitForUpdateImageCell = cell
        imagePicker.present(from: cell)
    }
}

extension PostViewController {
    private func updateRoomImages(cell: PostImageCell, image: UIImage) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        roomImages[indexPath.item] = image
        roomImagesStatus[indexPath.item] = true
    }

    private func uploadImages(images: [UIImage]) {
        let group = DispatchGroup()

        roomImagesUrl = []

        roomImagesUrl = oriRoomImagesUrl

        roomImagesStatus.enumerated().forEach { index, status in
            if status && images[index] != UIImage.asset(.add) {
                group.enter()
                FIRStorageService.shared.uploadImage(
                    image: images[index],
                    path: FIRStorageEndpoint.roomImages.path
                ) { [weak self] url, _ in
                    guard let self = self, let url = url else {
                        return
                    }
                    if self.oriRoomImagesUrl.count > index {
                        self.roomImagesUrl[index] = url
                    } else {
                        self.roomImagesUrl.append(url)
                    }
                    group.leave()
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
            modifiedTime: FirebaseService.shared.currentTimestamp,
            title: postBasicData.title ?? PostVCString.postTitle.rawValue,
            roomImages: roomImagesUrl,
            rooms: roomSpecList,
            roomFeatures: roomFeatures,
            roomPetsRules: roomPetsRules,
            roomHighLights: roomHighLights,
            roomGenderRules: roomGenderRules,
            roomCookingRules: roomCookingRules,
            roomElevatorRules: roomElevatorRules,
            roomBathroomRules: roomBathroomRules,
            town: postBasicData.town ?? PostVCString.town.rawValue,
            county: postBasicData.county ?? PostVCString.county.rawValue,
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
            FIRRoomService.shared.insertRoom(room: inputRoom) { [weak self] error in
                guard let self = self else { return }
                self.dealWithUpdateResult(error: error)
            }
        } else {
            if let room = room,
                let roomID = room.roomID {
                FIRRoomService.shared.updateRoomInfo(roomID: roomID, room: inputRoom) { [weak self] error in
                    guard let self = self else { return }
                    self.dealWithUpdateResult(error: error)
                }
            }
        }
    }

    private func dealWithUpdateResult(error: Error?) {
        if error != nil {
            RMProgressHUD.showFailure()
        } else {
            RMProgressHUD.showSuccess()
        }
        self.navigationController?.popViewController(animated: true)
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

// MARK: - Profile Image Picker Delegate
extension PostViewController: ImagePickerManagerDelegate {
    func imagePickerController(didSelect: UIImage?) {
        guard
            let image = didSelect,
            let waitForUpdateImageCell = waitForUpdateImageCell
        else { return }
        waitForUpdateImageCell.imageView.image = image
        updateRoomImages(cell: waitForUpdateImageCell, image: image)
    }
}
