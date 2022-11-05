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
        case basicInfo(Room)
    }

    var room: Room?

    var chatMembers: [ChatMember]?

    @IBOutlet weak var chatButton: UIButton! {
        didSet {
            chatButton.backgroundColor = .darkGray
            chatButton.tintColor = .white
            chatButton.layer.cornerRadius = 10
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: RoomBasicCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomBasicCell.reuseIdentifier)
            collectionView.register(
                UINib(nibName: RoomItemsCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomItemsCell.reuseIdentifier)
            collectionView.register(
                UINib(nibName: RoomFeeCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomFeeCell.reuseIdentifier)
            collectionView.register(
                UINib(nibName: RoomImagesCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomImagesCell.reuseIdentifier)
            collectionView.register(
                UINib(nibName: RoomDetailHeaderView.reuseIdentifier, bundle: nil),
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: RoomDetailHeaderView.reuseIdentifier)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.collectionViewLayout = createLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
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
extension RoomDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let room = room else {
            return 0
        }
        switch Section.allCases[section] {
        case .basicInfo, .feeDetail, .images:
            return 1
        case .amenities:
            return room.publicAmenities.count
        case .rules:
            return room.rules.count
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RoomDetailHeaderView.reuseIdentifier, for: indexPath) as? RoomDetailHeaderView else {
            fatalError("Cannot create RoomDetailHeaderView")
        }

        let title = Section.allCases[indexPath.section].rawValue
        switch Section.allCases[indexPath.section] {
        case .images:
            print("")
        case .basicInfo:
            print("")
        case .amenities:
            headerView.configureView(title: "設備")
        case .rules:
            headerView.configureView(title: "其他")
        case .feeDetail:
            headerView.configureView(title: "詳細訊息")
        }
        return headerView
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section.allCases[indexPath.section] {
        case .images:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomImagesCell.reuseIdentifier,
                for: indexPath
            ) as? RoomImagesCell,
                  let room = room else {
                return UICollectionViewCell()
            }

            cell.configureCell(images: room.roomImages)
            cell.delegate = self
            if let likeRooms = gCurrentUser.like {
                if likeRooms.contains(room.roomID) {
                    cell.islike = true
                }
            } else {
                cell.islike = false
            }
            return cell
        case .basicInfo:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomBasicCell.reuseIdentifier,
                for: indexPath
            ) as? RoomBasicCell,
                  let room = room else {
                return UICollectionViewCell()
            }

            cell.configureCell(
                area: "\(room.county)\(room.town)",
                roomSpecs: room.rooms,
                title: room.title
            )
            return cell
        case .amenities, .rules:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomItemsCell.reuseIdentifier,
                for: indexPath
            ) as? RoomItemsCell,
                  let room = room else {
                return UICollectionViewCell()
            }

            if Section.allCases[indexPath.section] == .rules {
                cell.configureCell(item: room.rules[indexPath.item])
            } else {
                cell.configureCell(item: room.publicAmenities[indexPath.item])
            }
            return cell
        case .feeDetail:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomFeeCell.reuseIdentifier,
                for: indexPath
            ) as? RoomFeeCell,
                  let room = room,
                  let billInfo = room.billInfo
            else {
                return UICollectionViewCell()
            }

            cell.configureCell(billInfo: billInfo)
            return cell
        }
    }

}

// MARK: Snapshot
//extension RoomDetailViewController {
//    private func updateDataSource() {
//        var newSnapshot = Snapshot()
//        newSnapshot.appendSections(Section.allCases)
//        if let room = room {
//            newSnapshot.appendItems([.basicInfo(room)], toSection: .basicInfo)
//        }
//        dataSource.apply(newSnapshot, animatingDifferences: true)
//    }
//}
extension RoomDetailViewController: UICollectionViewDelegate {

}
// MARK: Layout
extension RoomDetailViewController {
    func createBasicInfoSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.3)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
    }

    func createItemsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(0.1)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
    }

    func createFeeDetailSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.3)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
    }

    func createImagesSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(300)), subitems: [item])

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
        print("like", like)
        if let roomID = room?.roomID {
            if like == true {
                gCurrentUser.like?.append(roomID)
            } else {
                if let index = gCurrentUser.like?.firstIndex(of: roomID) {
                    gCurrentUser.like?.remove(at: index)
                }
            }
        }
        print(gCurrentUser.like)
    }
}
