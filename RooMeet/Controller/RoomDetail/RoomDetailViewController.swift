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
    typealias DetailDataSource = UICollectionViewDiffableDataSource<RoomDetailSection, RoomDetailItem>
    typealias DetailSnapshot = NSDiffableDataSourceSnapshot<RoomDetailSection, RoomDetailItem>
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
        RMProgressHUD.dismiss()

        if let room = room,
            let userData = room.userData {
            nameLabel.text = userData.name
            ageLabel.text = "\(userData.age)"
            genderImageView.image = Gender.allCases[userData.gender ?? 0].image
            if let profilePhoto = userData.profilePhoto {
                ownerAvatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
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
        if AuthService.shared.isLogin() {
            requestAction()
        } else {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .overFullScreen
            present(loginVC, animated: false)
        }
    }

    @IBAction func chatWithOwner(_ sender: Any) {
        if AuthService.shared.isLogin() {
            chatAction()
        } else {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .overFullScreen
            present(loginVC, animated: false)
        }
    }

    private func requestAction() {
        reservationButton.isEnabled = false
        guard let room = room else { return }

        guard
            let selectedPeriod = selectedPeriod,
            var selectedDate = selectedDate else {
            RMProgressHUD.showFailure(text: ReservationString.timeSelection.rawValue)
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
            self.user?.reservations.append(roomID)
            RMProgressHUD.showSuccess()
        } else {
            RMProgressHUD.showFailure(text: ReservationString.reserved.rawValue)
        }
        reservationButton.isEnabled = true
    }

    private func chatAction() {
        chatButton.isEnabled = false
        guard let room = room else {
            print("ERROR: - Room Detail got empty room.")
            return
        }

        FIRChatRoomService.shared.getChatRoomByMembers(members: [UserDefaults.id, room.userID]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatRoom):
                let chatVC = ChatViewController()
                chatVC.setup(chatRoom: chatRoom)
                self.hidesBottomBarWhenPushed = true
                DispatchQueue.main.async {
                    self.hidesBottomBarWhenPushed = false
                }
                self.navigationController?.pushViewController(chatVC, animated: false)
            case .failure(let error):
                debugPrint("replyReservation", error.localizedDescription)
            }
        }
        chatButton.isEnabled = true
    }

    @objc private func userAction(_ sender: Any) {
        if AuthService.shared.isLogin() {
            let reportPostAction = UIAlertAction(
                title: ReportString.actionTitle.rawValue,
                style: .destructive
            ) { [weak self] _ in
                guard
                    let self = self,
                    let roomID = self.room?.roomID
                else { return }

                let reportEvent = ReportEvent(reportUser: UserDefaults.id, type: "post", reportedID: roomID, createdTime: Timestamp())

                FIRUserService.shared.insertReportEvent(event: reportEvent) { error in
                    if error != nil {
                        RMProgressHUD.showFailure(text: ReportString.failure.rawValue)
                    } else {
                        RMProgressHUD.showSuccess(text: ReportString.success.rawValue)
                    }
                }
            }

            presentAlertVC(
                title: ReportString.title.rawValue,
                message: ReportString.message.rawValue,
                mainAction: reportPostAction,
                hasCancelAction: true
            )
        } else {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .overFullScreen
            present(loginVC, animated: false)
        }
    }
}

extension RoomDetailViewController {
    private func registerCell() {
        collectionView.registerCellWithNib(reuseIdentifier: RoomImagesCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: RoomBasicCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: RoomFeeCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: ItemsCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: BookingDateCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: BookingPeriodCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: RoomMapCell.reuseIdentifier, bundle: nil)
        collectionView.registerCellWithNib(reuseIdentifier: BookingPeriodCell.reuseIdentifier, bundle: nil)
        collectionView.registerHeaderWithNib(reuseIdentifier: RoomDetailHeaderView.reuseIdentifier, bundle: nil)
    }

    private func configureCollectionView() {
        registerCell()

        collectionView.collectionViewLayout = createLayout()

        dataSource = DetailDataSource(collectionView: collectionView) { [self] collectionView, indexPath, item in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: item.cellIdentifier,
                    for: indexPath
                ) as? RoomDetailCell
            else {
                return UICollectionViewCell()
            }

            cell.configure(container: item.container)

            switch item {
            case .basicInfo(let data):
                (cell as? RoomBasicCell)?.delegate = self
                if AuthService.shared.isLogin() {
                    if
                        let user = self.user,
                        let roomID = data.roomID {
                        if user.favoriteRoomIDs.contains(roomID) {
                            (cell as? RoomBasicCell)?.isLike = true
                        }
                    }
                }
            case .reservationDays:
                (cell as? BookingDateCell)?.delegate = self
            case .reservationPeriod:
                (cell as? BookingPeriodCell)?.delegate = self
            default:
                print("")
            }
            return cell
        }

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: RoomDetailHeaderView.reuseIdentifier,
                for: indexPath) as? RoomDetailHeaderView else {
                fatalError("Could not dequeue sectionHeader: \(RoomDetailHeaderView.reuseIdentifier)")
            }

            sectionHeader.titleLabel.text = RoomDetailSection.allCases[indexPath.section].title
            return sectionHeader
        }
    }
}

// MARK: Layout
extension RoomDetailViewController {
    private func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = RoomDetailSection.allCases[index]
        return section.layoutSection
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] index, env in
            return self?.sectionFor(index: index, environment: env)
        }
    }
}

// MARK: - Basic Delegate
extension RoomDetailViewController: RoomBasicCellDelegate {
    func didClickedLike(_ cell: RoomBasicCell, like: Bool) {
        if AuthService.shared.isLogin() {
            if
                let room = room,
                let roomID = room.roomID {
                if like {
                    let favoriteRoom = FavoriteRoom(roomID: roomID, createdTime: Timestamp())
                    user?.favoriteRooms.append(favoriteRoom)
                } else {
                    guard let user = user else { return }
                    self.user?.favoriteRooms = user.favoriteRooms.filter { $0.roomID != room.roomID }
                }
                cell.isLike.toggle()
                shouldUpdate = true
            }
        } else {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .overFullScreen
            present(loginVC, animated: false)
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
        var sections = RoomDetailSection.allCases
        if room.billInfo != nil {
            newSnapshot.appendSections(sections)

            newSnapshot.appendItems(
                room.billInfoList.map { roomDetailFees in
                    roomDetailFees.map { RoomDetailItem.feeDetail($0) }
                }!,
                toSection: .feeDetail
            )
        } else {
            guard let index = sections.firstIndex(of: .feeDetail) else { return }
            sections.remove(at: index)
            newSnapshot.appendSections(sections)
        }

        newSnapshot.appendItems([.images(room)], toSection: .images)
        newSnapshot.appendItems([.pet(room)], toSection: .pet)
        newSnapshot.appendItems([.elevator(room)], toSection: .elevator)
        newSnapshot.appendItems([.cooking(room)], toSection: .cooking)
        newSnapshot.appendItems([.bathroom(room)], toSection: .bathroom)
        newSnapshot.appendItems([.features(room)], toSection: .features)
        newSnapshot.appendItems([.gender(room)], toSection: .gender)
        newSnapshot.appendItems([.highLight(room)], toSection: .highLight)
        newSnapshot.appendItems([.basicInfo(room)], toSection: .basicInfo)

        newSnapshot.appendItems(dates.map { RoomDetailItem.reservationDays($0) }, toSection: .reservationDays)
        newSnapshot.appendItems([.reservationPeriod(room)], toSection: .reservationPeriod)
        newSnapshot.appendItems([.map(room)], toSection: .map)

        dataSource.apply(newSnapshot)
    }
}

extension RoomDetailViewController: BookingDateCellDelegate {
    func didSelectedDate(_ cell: BookingDateCell, date: DateComponents) {
        if selectedDateCell == nil {
            selectedDate = date
            selectedDateCell = cell
            selectedDateCell?.isSelected = true
        } else {
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
