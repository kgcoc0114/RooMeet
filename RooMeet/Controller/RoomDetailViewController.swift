//
//  RoomDetailViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import UIKit

class RoomDetailViewController: UIViewController {
    enum Section: String, CaseIterable {
        case images
        case basicInfo
        case amenities
        case rules
        case feeDetail
    }

    enum Item: Hashable {
        case images(Room)
        case basicInfo(Room)
        case amenities(String)
        case rules(String)
        case feeDetail(BillInfo)
    }

    typealias DetailDataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias DetailSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DetailDataSource!

    var room: Room?

    var chatMembers: [ChatMember]?

    @IBOutlet weak var chatButton: UIButton! {
        didSet {
            chatButton.backgroundColor = .darkGray
            chatButton.tintColor = .white
            chatButton.layer.cornerRadius = 10
        }
    }

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
        configureCollectionView()
        collectionView.collectionViewLayout = createLayout()
        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let room = room,
            let userData = room.userData {
            chatButton.setTitle("Chat with \(userData.name ?? "Owner")", for: .normal)
        }
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseService.shared.updateUserLikeData()
        self.tabBarController?.tabBar.isHidden = false
    }


    @IBAction func chatWithOwner(_ sender: Any) {
        FirebaseService.shared.upsertChatRoomByUserID(userA: gCurrentUser.id, userB: room!.userID) { [weak self] chatRoom in
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
            UINib(nibName: "RoomItemsCell", bundle: nil),
            forCellWithReuseIdentifier: RoomItemsCell.identifier)
        collectionView.register(
            UINib(nibName: "RoomFeeCell", bundle: nil),
            forCellWithReuseIdentifier: RoomFeeCell.identifier)

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
                    withReuseIdentifier: RoomItemsCell.identifier,
                    for: indexPath
                ) as? RoomItemsCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(data: data)
                return cell
            case .amenities(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomItemsCell.identifier,
                    for: indexPath
                ) as? RoomItemsCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(data: data, itemType: "amenities")
                return cell
            case .feeDetail(let data):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RoomFeeCell.identifier,
                    for: indexPath
                ) as? RoomFeeCell else {
                    return UICollectionViewCell()
                }
                cell.configureCell(data: data)
                return cell
            }
        }

        collectionView.collectionViewLayout = createLayout()
    }
}

// MARK: Layout
extension RoomDetailViewController {
    func createBasicInfoSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(150)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
    }

    func createItemsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(20),
                heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(20),
                heightDimension: .estimated(50)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 0)
        return section
    }

    func createFeeDetailSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.3)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
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

        return NSCollectionLayoutSection(group: group)
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
                gCurrentUser.like?.append(roomID)
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
        newSnapshot.appendSections([.images, .basicInfo, .rules, .amenities, .feeDetail])
        newSnapshot.appendItems([.images(room)], toSection: .images)
        newSnapshot.appendItems(room.rules.map({ Item.rules($0) }), toSection: .rules)
        newSnapshot.appendItems(room.publicAmenities.map({ Item.amenities($0) }), toSection: .amenities)
        newSnapshot.appendItems([.basicInfo(room)], toSection: .basicInfo)
        if let billInfo = room.billInfo {
            newSnapshot.appendItems([.feeDetail(billInfo)], toSection: .feeDetail)
        }
        dataSource.apply(newSnapshot)
    }
}
