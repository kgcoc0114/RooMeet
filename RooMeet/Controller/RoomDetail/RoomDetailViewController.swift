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
        case map
        case amenities
        case rules
        case feeDetail
        case reservationDays
        case reservationPeriod

        var title: String {
            switch self {
            case .images:
                return ""
            case .basicInfo:
                return ""
            case .amenities:
                return "亮點"
            case .rules:
                return "注意"
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
        case amenities(String)
        case rules(String)
        case feeDetail(RoomDetailFee)
        case reservationDays(DateComponents)
        case reservationPeriod(Room)
        case map(Room)
    }

    typealias DetailDataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias DetailSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DetailDataSource!

    var room: Room?
    var selectedPeriod: BookingPeriod?
    var selectedDate: DateComponents?
    var selectedDateCell: BookingDateCell?

    var chatMembers: [ChatMember]?
    private var feeDetails: [RoomDetailFee] = []

    lazy private var dates = Date().getDaysInWeek(days: RMConstants.shared.reservationDays)

    @IBOutlet weak var chatButton: UIButton! {
        didSet {
            chatButton.setTitle(" 聊聊", for: .normal)
            chatButton.setImage(UIImage(systemName: "message"), for: .normal)
            chatButton.titleLabel?.font = UIFont.regular(size: 18)
            chatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            chatButton.backgroundColor = .darkGray
            chatButton.tintColor = .white
            chatButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var reservationButton: UIButton! {
        didSet {
            reservationButton.setTitle(" 預約", for: .normal)
            reservationButton.setImage(UIImage(systemName: "calendar"), for: .normal)
            reservationButton.titleLabel?.font = UIFont.regular(size: 18)
            reservationButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            reservationButton.backgroundColor = .darkGray
            reservationButton.tintColor = .white
            reservationButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.font = UIFont.regular(size: 18)
        }
    }

    @IBOutlet weak var ageLabel: UILabel! {
        didSet {
            ageLabel.font = UIFont.regular(size: 14)
        }
    }

    @IBOutlet weak var genderImageView: UIImageView!

    @IBOutlet weak var collectionView: UICollectionView!

    init(room: Room) {
        super.init(nibName: "RoomDetailViewController", bundle: nil)

        self.room = room
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "icon_back"),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.title = "RooMeet"

        configureCollectionView()
        collectionView.collectionViewLayout = createLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let room = room,
            let userData = room.userData {
            nameLabel.text = userData.name
            ageLabel.text = "\(userData.age)"
            genderImageView.image = Gender.allCases[userData.gender].image
        }
        dealWithBillInfo()
        self.tabBarController?.tabBar.isHidden = true
        updateDataSource()
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseService.shared.updateUserLikeData()
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func requestReservation(_ sender: Any) {
        guard let room = room  else { return }

        guard let selectedPeriod = selectedPeriod,
            let selectedDate = selectedDate else {
            print("請選擇預約時間")
            RMProgressHUD.showFailure(text: "請選擇預約時間", view: self.view)
            return
        }

        guard let sDate = selectedDate.date else {
            print("ERROR: - Reservations Date got error.")
            return
        }

        if let reservations = gCurrentUser.reservations {
            if !reservations.contains(room.roomID) {
                ReservationService.shared.upsertReservationData(
                    status: .waiting,
                    requestTime: sDate,
                    period: selectedPeriod.descrption,
                    room: room,
                    senderID: gCurrentUser.id,
                    receiverID: room.userID,
                    reservation: nil
                )
                RMProgressHUD.showSuccess(view: self.view)
            } else {
                RMProgressHUD.showFailure(text: "已預約過此房源", view: self.view)
            }
        } else {
            ReservationService.shared.upsertReservationData(
                status: .waiting,
                requestTime: sDate,
                period: selectedPeriod.descrption,
                room: room,
                senderID: gCurrentUser.id,
                receiverID: room.userID,
                reservation: nil
            )
            RMProgressHUD.showSuccess(view: self.view)
        }
    }

    @IBAction func chatWithOwner(_ sender: Any) {
        guard let room = room else {
            print("ERROR: - Room Detail got empty room.")
            return
        }

        FirebaseService.shared.upsertChatRoomByUserID(userA: gCurrentUser.id, userB: room.userID) { [weak self] chatRoom in
            let detailVC = ChatViewController()
            detailVC.setup(chatRoom: chatRoom)
            self?.navigationController?.pushViewController(detailVC, animated: false)
        }
    }
}

extension RoomDetailViewController {
    private func configureCollectionView() {
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
            UINib(nibName: "TagCell", bundle: nil),
            forCellWithReuseIdentifier: TagCell.identifier)
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

        dataSource = DetailDataSource(collectionView: collectionView) { collectionView, indexPath, item in
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
                cell.delegate = self
                if let likeRooms = gCurrentUser.like {
                    if likeRooms.contains(data.roomID) {
                        cell.isLike = true
                    }
                } else {
                    cell.isLike = false
                }
                return cell

            case .basicInfo(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomBasicCell.identifier,
                    for: indexPath
                ) as? RoomBasicCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(data: data)
                return cell
            case .rules(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TagCell.identifier,
                    for: indexPath
                ) as? TagCell else {
                    return UICollectionViewCell()
                }
                cell.styleCell(backgroundColor: .hexColor(hex: "#D89A9E"), tintColor: .black)
                cell.configureCell(data: data)
                return cell
            case .amenities(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TagCell.identifier,
                    for: indexPath
                ) as? TagCell else {
                    return UICollectionViewCell()
                }
                cell.styleCell(backgroundColor: .hexColor(hex: "#1C6E8C"), tintColor: .white)
                cell.configureCell(data: data)
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
            case .reservationPeriod(let data):
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
                    latitude: data.lat ?? gCurrentPosition.latitude,
                    longitude: data.long ?? gCurrentPosition.longitude
                )
                return cell
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
}

// MARK: Layout
extension RoomDetailViewController {
    func createBasicInfoSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)), subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        return section    }

    func createItemsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(20),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(20),
            heightDimension: .absolute(30)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )


        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

        // SectionHeader
        section.boundarySupplementaryItems = [createSectionHeader()]
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
        case .basicInfo:
            return createBasicInfoSection()
        case .feeDetail:
            return createFeeDetailSection()
        case .amenities, .rules:
            return createItemsSection()
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

extension RoomDetailViewController: RoomImagesCellDelegate {
    func didClickedLike(like: Bool) {
        if let roomID = room?.roomID {
            if like == true {
                if gCurrentUser.like != nil {
                    gCurrentUser.like?.append(roomID)
                } else {
                    gCurrentUser.like = []
                    gCurrentUser.like?.append(roomID)
                }
            } else {
                if let index = gCurrentUser.like?.firstIndex(of: roomID) {
                    gCurrentUser.like?.remove(at: index)
                }
            }
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

        newSnapshot.appendItems(room.rules.map { Item.rules($0) }, toSection: .rules)
        newSnapshot.appendItems(room.publicAmenities.map { Item.amenities($0) }, toSection: .amenities)
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
