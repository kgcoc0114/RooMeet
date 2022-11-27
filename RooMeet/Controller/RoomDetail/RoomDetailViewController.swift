//
//  RoomDetailViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

struct RoomDetailFee: Hashable {
    let billType: BillType
    let feeDatail: FeeDetail
}

class RoomDetailViewController: UIViewController {
    enum Section: String, CaseIterable {
        case images
        case basicInfo
        case reservationDays
        case reservationPeriod
        case map
        case highLight
        case gender
        case pet
        case elevator
        case cooking
        case bathroom
        case features
        case feeDetail


        var title: String {
            switch self {
            case .images:
                return ""
            case .basicInfo:
                return ""
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
            case .feeDetail:
                return "費用明細"
            case .reservationDays:
                return "預約看房"
            case .reservationPeriod:
                return ""
            case .map:
                return "地圖"
            }
        }
    }

    enum Item: Hashable {
        case images(Room)
        case basicInfo(Room)
        case highLight(Room)
        case gender(Room)
        case pet(Room)
        case elevator(Room)
        case cooking(Room)
        case bathroom(Room)
        case features(Room)
        case feeDetail(RoomDetailFee)
        case reservationDays(DateComponents)
        case reservationPeriod(Room)
        case map(Room)
    }

    typealias DetailDataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias DetailSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DetailDataSource!

    var room: Room?
    var user: User?

    var selectedPeriod: BookingPeriod?
    var selectedDate: DateComponents?
    var selectedDateCell: BookingDateCell?

    var shouldUpdate = false

    var chatMembers: [ChatMember]?
    private var feeDetails: [RoomDetailFee] = []

    lazy private var dates = Date().getDaysInWeek(days: RMConstants.shared.reservationDays)

    @IBOutlet weak var backButton: UIButton! {
        didSet {
            backButton.setImage(UIImage.asset(.back), for: .normal)
        }
    }

    @IBOutlet weak var chatButton: UIButton! {
        didSet {
            chatButton.setTitle(" 聊聊", for: .normal)
            chatButton.setImage(UIImage(systemName: "message"), for: .normal)
            chatButton.titleLabel?.font = .regularSubTitle()
            chatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            chatButton.backgroundColor = .mainColor
            chatButton.tintColor = .mainBackgroundColor
            chatButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius * 0.8
        }
    }

    @IBOutlet weak var reservationButton: UIButton! {
        didSet {
            reservationButton.setTitle(" 預約", for: .normal)
            reservationButton.setImage(UIImage(systemName: "calendar"), for: .normal)
            reservationButton.titleLabel?.font = .regularSubTitle()
            reservationButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            reservationButton.backgroundColor = .mainColor
            reservationButton.tintColor = .mainBackgroundColor
            reservationButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius * 0.8
        }
    }

    @IBOutlet weak var ownerAvatarView: UIImageView! {
        didSet {
            ownerAvatarView.contentMode = .scaleAspectFill
        }
    }

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var ageLabel: UILabel! {
        didSet {
            ageLabel.font = UIFont.regularText()
        }
    }

    @IBOutlet weak var genderImageView: UIImageView!

    @IBOutlet weak var collectionView: UICollectionView!

    init(room: Room, user: User?) {
        super.init(nibName: "RoomDetailViewController", bundle: nil)

        self.user = user
        self.room = room
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.comment_info).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(userAction))

        navigationItem.title = "RooMeet"

        configureCollectionView()
        collectionView.collectionViewLayout = createLayout()
    }

    @IBOutlet weak var buttomView: UIView! {
        didSet {
            buttomView.backgroundColor = .mainLightColor
            buttomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            buttomView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let room = room,
            let userData = room.userData {
            nameLabel.text = userData.name
            ageLabel.text = "\(userData.age)"
            genderImageView.image = Gender.allCases[userData.gender ?? 0].image
            if let profilePhoto = userData.profilePhoto {
                ownerAvatarView.setImage(urlString: profilePhoto)
            } else {
                ownerAvatarView.image = UIImage.asset(.roomeet)
            }
        }

        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self,
                let user = user else { return }
            self.user = user
        }

        dealWithBillInfo()
        updateDataSource()
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        ownerAvatarView.layer.cornerRadius = ownerAvatarView.bounds.width / 2
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        navigationController?.navigationBar.isHidden = false

        if shouldUpdate {
            guard let user = user else { return }

            FirebaseService.shared.updateUserFavData(
                favoriteRooms: user.favoriteRooms
            )
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }

    private func dealWithBillInfo() {
        if
            let room = room,
            let billInfo = room.billInfo {
            BillType.allCases.forEach { billType in
                let feeDetail = billType.feeDetail(billInfo: billInfo)

                if feeDetail.paid == true {
                    let roomDetailFee = RoomDetailFee(billType: billType, feeDatail: feeDetail)
                    feeDetails.append(roomDetailFee)
                }
            }
        }
    }

    @IBAction func requestReservation(_ sender: Any) {
        reservationButton.isEnabled = false
        guard let room = room else { return }

        guard let selectedPeriod = selectedPeriod,
            var selectedDate = selectedDate else {
            print("請選擇預約時間")
            RMProgressHUD.showFailure(text: "請選擇預約時間")
            reservationButton.isEnabled.toggle()
            return
        }

        selectedDate.hour = selectedPeriod.hour

        guard let sDate = selectedDate.date else {
            print("ERROR: - Reservations Date got error.")
            reservationButton.isEnabled.toggle()
            return
        }

        guard
            let user = user,
            let roomID = room.roomID else {
            reservationButton.isEnabled.toggle()
            return
        }

        if !user.reservations.contains(roomID) {
            ReservationService.shared.upsertReservationData(
                status: .waiting,
                requestTime: sDate,
                period: selectedPeriod.subDesc,
                room: room,
                senderID: UserDefaults.id,
                receiverID: room.userID,
                reservation: nil
            )
            RMProgressHUD.showSuccess()
        } else {
            RMProgressHUD.showFailure(text: "已預約過此房源")
        }
        reservationButton.isEnabled = true
    }

    @IBAction func chatWithOwner(_ sender: Any) {
        chatButton.isEnabled = false
        guard let room = room else {
            print("ERROR: - Room Detail got empty room.")
            return
        }

        FirebaseService.shared.getChatRoomByUserID(userA: UserDefaults.id, userB: room.userID) { [weak self] chatRoom in
            guard let self = self else { return }
            let chatVC = ChatViewController()
            chatVC.setup(chatRoom: chatRoom)
            self.hidesBottomBarWhenPushed = true
            DispatchQueue.main.async {
                self.hidesBottomBarWhenPushed = false
            }
            self.navigationController?.pushViewController(chatVC, animated: false)
        }
        chatButton.isEnabled = true
    }

    @objc private func userAction(_ sender: Any) {
        let userActionAlertController = UIAlertController(
            title: "檢舉",
            message: "確定檢舉此則貼文，你的檢舉將被匿名。",
            preferredStyle: .actionSheet
        )

        let reportPostAction = UIAlertAction(title: "檢舉貼文", style: .default) { [weak self] _ in
            guard
                let self = self,
                let roomID = self.room?.roomID
            else { return }

            let reportEvent = ReportEvent(reportUser: UserDefaults.id, type: "post", reportedID: roomID, createdTime: Timestamp())

            FirebaseService.shared.insertReportEvent(event: reportEvent) { error in
                if error != nil {
                    RMProgressHUD.showFailure(text: "出點問題了，請稍後再試！")
                } else {
                    RMProgressHUD.showSuccess(text: "成功送出檢舉！")
                }
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            userActionAlertController.dismiss(animated: true)
        }

        userActionAlertController.addAction(reportPostAction)
        userActionAlertController.addAction(cancelAction)

        present(userActionAlertController, animated: true, completion: nil)
    }
}

extension RoomDetailViewController {
    private func registerCell() {
        collectionView.register(
            UINib(nibName: "RoomImagesCell", bundle: nil),
            forCellWithReuseIdentifier: RoomImagesCell.identifier)
        collectionView.register(
            UINib(nibName: "RoomBasicCell", bundle: nil),
            forCellWithReuseIdentifier: RoomBasicCell.identifier)
        collectionView.register(
            UINib(nibName: "RoomFeeCell", bundle: nil),
            forCellWithReuseIdentifier: RoomFeeCell.identifier)
        collectionView.register(
            UINib(nibName: "BookingCell", bundle: nil),
            forCellWithReuseIdentifier: BookingCell.identifier)
        collectionView.register(
            UINib(nibName: ItemsCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: ItemsCell.reuseIdentifier)
        collectionView.register(
            UINib(nibName: "BookingDateCell", bundle: nil),
            forCellWithReuseIdentifier: BookingDateCell.identifier)
        collectionView.register(
            UINib(nibName: "BookingPeriodCell", bundle: nil),
            forCellWithReuseIdentifier: BookingPeriodCell.identifier)
        collectionView.register(
            UINib(nibName: "RoomMapCell", bundle: nil),
            forCellWithReuseIdentifier: RoomMapCell.identifier)
        collectionView.register(
            UINib(nibName: "RoomDetailHeaderView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: RoomDetailHeaderView.identifier)
    }

    private func configureCollectionView() {
        registerCell()

        dataSource = DetailDataSource(collectionView: collectionView) { [self] collectionView, indexPath, item in
            switch item {
            case .images(let data):
                guard
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: RoomImagesCell.identifier,
                        for: indexPath
                    ) as? RoomImagesCell
                else {
                    return UICollectionViewCell()
                }

                cell.configureCell(images: data.roomImages)
                return cell

            case .basicInfo(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomBasicCell.identifier,
                    for: indexPath
                ) as? RoomBasicCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(data: data)
                cell.delegate = self

                if
                    let user = self.user,
                    let roomID = data.roomID {
                    if user.favoriteRoomIDs.contains(roomID) {
                        cell.isLike = true
                    }
                } else {
                    cell.isLike = false
                }
                return cell
            case .feeDetail(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomFeeCell.identifier,
                    for: indexPath
                ) as? RoomFeeCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(billType: data.billType, data: data.feeDatail)
                return cell
            case .reservationDays(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: BookingDateCell.identifier,
                    for: indexPath
                ) as? BookingDateCell else {
                    return UICollectionViewCell()
                }
                cell.delegate = self
                cell.configureCell(date: data)
                return cell
            case .reservationPeriod(_):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: BookingPeriodCell.identifier,
                    for: indexPath
                ) as? BookingPeriodCell else {
                    return UICollectionViewCell()
                }
                cell.delegate = self
                return cell
            case .map(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomMapCell.identifier,
                    for: indexPath
                ) as? RoomMapCell else {
                    return UICollectionViewCell()
                }
                print(data)
                cell.configureCell(
                    latitude: data.lat ?? RMConstants.shared.currentPosition.latitude,
                    longitude: data.long ?? RMConstants.shared.currentPosition.longitude
                )
                return cell
            case .highLight(let data),
                .gender(let data),
                .pet(let data),
                .elevator(let data),
                .cooking(let data),
                .bathroom(let data),
                .features(let data):
                return genTagCell(item: data, indexPath: indexPath)
            }
        }

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: RoomDetailHeaderView.identifier,
                for: indexPath) as? RoomDetailHeaderView else {
                fatalError("Could not dequeue sectionHeader: \(RoomDetailHeaderView.identifier)")
            }

            sectionHeader.titleLabel.text = Section.allCases[indexPath.section].title
            return sectionHeader
        }

        collectionView.collectionViewLayout = createLayout()
    }

    func genTagCell(item: Room, indexPath: IndexPath) -> ItemsCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ItemsCell.reuseIdentifier,
            for: indexPath
        ) as? ItemsCell,
            let room = room else {
            return UICollectionViewCell() as! ItemsCell
        }

        var tags: [String] = []
        var mainColor = UIColor.mainColor
        var lightColor = UIColor.mainBackgroundColor

        let section = Section.allCases[indexPath.section]
        switch section {
        case .highLight:
            tags = room.roomHighLights
        case .gender:
            tags = room.roomGenderRules
        case .pet:
            tags = room.roomPetsRules
        case .elevator:
            tags = room.roomElevatorRules
        case .cooking:
            tags = room.roomCookingRules
        case .bathroom:
            tags = room.roomBathroomRules
        case .features:
            tags = room.roomFeatures
            mainColor = UIColor.subTitleColor
            lightColor = UIColor.mainBackgroundColor
        default:
            break
        }
        cell.configureTitleInDetailPage()
        cell.configureTagView(
            ruleType: section.title,
            tags: tags,
            selectedTags: tags,
            mainColor: mainColor,
            lightColor: lightColor,
            mainLightBackgroundColor: UIColor.white,
            enableTagSelection: false)

        return cell
    }
}

// MARK: Layout
extension RoomDetailViewController {
    func createBasicInfoSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)), subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return section
    }

    private func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        return header
    }

    func createFeeDetailSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
        // SectionHeader
        section.boundarySupplementaryItems = [createSectionHeader()]
        return section
    }

    func createImagesSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(300)),
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        return section
    }

    func createReservationDaysSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth((1 / CGFloat(RMConstants.shared.reservationDays))),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(75)),
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        // SectionHeader
        section.boundarySupplementaryItems = [createSectionHeader()]
        return section
    }

    func createMapSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(150)),
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

        // SectionHeader
        section.boundarySupplementaryItems = [createSectionHeader()]
        return section
    }

    func createReservationPeriodSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(60)),
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

        return section
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = Section.allCases[index]
        switch section {
        case .basicInfo, .highLight, .gender, .pet, .elevator, .cooking, .bathroom, .features:
            return createBasicInfoSection()
        case .feeDetail:
            return createFeeDetailSection()
        case .images:
            return createImagesSection()
        case .reservationDays:
            return createReservationDaysSection()
        case .reservationPeriod:
            return createReservationPeriodSection()
        case .map:
            return createMapSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] index, env in
            return self.sectionFor(index: index, environment: env)
        }
    }
}

extension RoomDetailViewController: RoomBasicCellDelegate {
    func didClickedLike(like: Bool) {
        if let room = room,
            let roomID = room.roomID {
            if like {
                let favoriteRoom = FavoriteRoom(roomID: roomID, createdTime: Timestamp())
                user?.favoriteRooms.append(favoriteRoom)
            } else {
                if let index = user?.favoriteRoomIDs.firstIndex(of: roomID) {
                    user?.favoriteRooms.remove(at: index)
                }
            }
            shouldUpdate = true
        }
    }
}

// MARK: - Snapshot
extension RoomDetailViewController {
    private func updateDataSource() {
        var newSnapshot = DetailSnapshot()
        guard let room = room else {
            return
        }
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems([.images(room)], toSection: .images)
        newSnapshot.appendItems([.pet(room)], toSection: .pet)
        newSnapshot.appendItems([.elevator(room)], toSection: .elevator)
        newSnapshot.appendItems([.cooking(room)], toSection: .cooking)
        newSnapshot.appendItems([.bathroom(room)], toSection: .bathroom)
        newSnapshot.appendItems([.features(room)], toSection: .features)
        newSnapshot.appendItems([.gender(room)], toSection: .gender)
        newSnapshot.appendItems([.highLight(room)], toSection: .highLight)
        newSnapshot.appendItems([.basicInfo(room)], toSection: .basicInfo)
        if room.billInfo != nil {
            newSnapshot.appendItems(
                room.billInfoList.map { roomDetailFees in
                    roomDetailFees.map { Item.feeDetail($0) }
                }!,
                toSection: .feeDetail
            )
        }
        newSnapshot.appendItems(dates.map { Item.reservationDays($0) }, toSection: .reservationDays)
        newSnapshot.appendItems([.reservationPeriod(room)], toSection: .reservationPeriod)
        newSnapshot.appendItems([.map(room)], toSection: .map)

        dataSource.apply(newSnapshot)
    }
}

extension RoomDetailViewController: BookingDateCellDelegate {
    func didSelectedDate(_ cell: BookingDateCell, date: DateComponents) {
        // 第一次選擇
        if selectedDateCell == nil {
            selectedDate = date
            selectedDateCell = cell
            selectedDateCell?.isSelected = true
        } else {
            // 取消此次選擇
            if cell == selectedDateCell {
                selectedDateCell?.isSelected = false
                selectedDate = nil
                selectedDateCell = nil
            } else {
                selectedDateCell?.isSelected = false
                cell.isSelected = true
                selectedDate = date
                selectedDateCell = cell
            }
        }
    }
}

extension RoomDetailViewController: BookingPeriodCellDelegate {
    func didSelectPeriod(selectedPeriod: BookingPeriod) {
        self.selectedPeriod = selectedPeriod
    }
}
