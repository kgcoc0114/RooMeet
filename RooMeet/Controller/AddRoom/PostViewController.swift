//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit
import FirebaseStorage

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
    var roomImages: [UIImage] = []

    var otherDescriction: String?
    var latitude: Double?
    var longitude: Double?
    var postalCode: String?
    var createdTime = FirebaseService.shared.currentTimestamp
    var isDeleted = false
    var room: Room?
    let postScenario: PostScenario

    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.setTitle(postScenario.pageTitle + PostVCString.submit.rawValue, for: .normal)
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


    init(postScenario: PostScenario) {
        self.postScenario = postScenario

        super.init(nibName: "PostViewController", bundle: nil)

        switch postScenario {
        case .create:
            break
        case .edit(let room):
            self.room = room
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.keyboardDismissMode = .interactive
        navigationItem.title = postScenario.pageTitle + PostVCString.title.rawValue

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        switch postScenario {
        case .create:
            break
        case .edit:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage.asset(.trash).withRenderingMode(.alwaysOriginal),
                style: .plain,
                target: self,
                action: #selector(deletePostAction))
            configureData(postScenario: postScenario)
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

    func configureData(postScenario: PostScenario) {
        roomSpecList = postScenario.roomSpecList
        roomHighLights = postScenario.roomHighLights
        roomGenderRules = postScenario.roomGenderRules
        roomPetsRules = postScenario.roomPetsRules
        roomElevatorRules = postScenario.roomElevatorRules
        roomCookingRules = postScenario.roomCookingRules
        roomFeatures = postScenario.roomFeatures
        roomBathroomRules = postScenario.roomBathroomRules
        featureSelection = postScenario.roomFeatures
        billInfo = postScenario.billInfo
        postBasicData = postScenario.postBasicData
        oriRoomImagesUrl = postScenario.roomImagesUrl
        roomImagesUrl = postScenario.roomImagesUrl
        otherDescriction = postScenario.otherDescriction
        latitude = postScenario.latitude
        longitude = postScenario.longitude
        createdTime = postScenario.createdTime
        roomImages = postScenario.roomDisplayImages
    }

    private func isSavable() -> Bool {
        guard let postBasicData = postBasicData else {
            return false
        }

        if postBasicData.title == nil || postBasicData.county == nil || postBasicData.movinDate == nil ||
             roomSpecList.isEmpty {
            return false
        }
        return true
    }

    @IBAction func submitAction(_ sender: Any) {
        var alert = false
        guard let postBasicData = postBasicData else {
            showAlert()
            return
        }
        
        if postBasicData.title == nil || postBasicData.county == nil || postBasicData.movinDate == nil ||
            roomSpecList.isEmpty {
            showAlert()
        } else {
            roomSpecList.forEach { roomSpec in
                if roomSpec.price == nil || roomSpec.space == nil {
                    alert = true
                    showAlert(message: PostVCString.roomSpecAlertMessage.rawValue)
                }
            }
            if alert == false {
                if roomImages.isEmpty {
                    room?.roomImages = []
                    saveData()
                } else {
                    uploadImages(images: roomImages)
                }
            }
        }
    }

    @objc private func deletePostAction() {
        let alertController = UIAlertController(
            title: PostVCString.delete.rawValue,
            message: PostVCString.deleteMessage.rawValue,
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(
            title: PostVCString.deleteActionTitle.rawValue,
            style: .destructive
        ) { [unowned self] _ in
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

        let cancelAction = UIAlertAction(title: PostVCString.cancel.rawValue, style: .cancel) { _ in
            alertController.dismiss(animated: true)
        }

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    private func showAlert(message: String = PostVCString.addMessage.rawValue) {
        let alertController = UIAlertController(
            title: PostVCString.add.rawValue,
            message: message,
            preferredStyle: .alert
        )
        let alertAction = UIAlertAction(title: PostVCString.confirm.rawValue, style: .default)
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
        let section = PostSection.allCases[indexPath.section]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: section.cellIdentifier,
            for: indexPath) as? PostCell else {
            print("ERROR: - PostCell Generate error")
            return UICollectionViewCell()
        }

        cell.configure(container: PostDataContainer(
            postScenario: postScenario,
            section: section,
            indexPath: indexPath
        ))


        switch section{
        case .basic:
            (cell as? PostBasicCell)?.delegate = self
        case .roomSpec:
            congifureRoomSpecCell(cell: cell)
        case .images:
            (cell as? PostImageCell)?.delegate = self
        case .feeHeader:
            (cell as? OtherFeeHeaderCell)?.editAction.addTarget(self, action: #selector(showMultiChoosePage), for: .touchUpInside)
        case .feeDetail:
            (cell as? FeeDetailCell)?.completion = { [unowned self] otherDesc in
                self.otherDescriction = otherDesc
            }
        case .highLight, .gender, .pet, .elevator, .cooking, .features, .bathroom:
            (cell as? ItemsCell)?.delegate = self
        }
        return cell
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }

    private func congifureRoomSpecCell(cell: PostCell) {
        (cell as? RoomSpecCell)?.delegate = self

        (cell as? RoomSpecCell)?.addColumnAction = { [weak self] cell in
            guard
                let self = self,
                let indexPath = self.collectionView.indexPath(for: cell) else { return }
            let roomSpec = RoomSpec()
            self.roomSpecList.insert(roomSpec, at: indexPath.item + 1)
            self.collectionView.reloadData()
        }

        (cell as? RoomSpecCell)?.delectColumnAction = { [weak self] cell in
            guard
                let self = self,
                let indexPath = self.collectionView.indexPath(for: cell) else { return }

            self.roomSpecList.remove(at: indexPath.item)
            self.collectionView.reloadData()
        }
    }
}

extension PostViewController: UICollectionViewDelegate {
    @objc func showMultiChoosePage(_ sender: UIButton) {
        let postSection = PostSection.allCases[sender.tag]
        switch postSection {
        case .feeHeader:
            let editFeeVC = EditFeeController(billInfo: billInfo)

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
            PostSection.allCases[sectionIndex].sectionLayout
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

        switch postScenario {
        case .create:
            FirebaseService.shared.insertRoom(room: inputRoom) { error in
                RMProgressHUD.dismiss()

                if error != nil {
                    RMProgressHUD.showFailure()
                } else {
                    RMProgressHUD.showSuccess()
                }
                self.navigationController?.popViewController(animated: true)
            }
        case .edit:
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
