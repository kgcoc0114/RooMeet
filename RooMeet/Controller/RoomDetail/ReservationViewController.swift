//
//  ReservationViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class ReservationViewController: UIViewController {
    enum Section {
        case main
    }

    typealias HomeDataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias HomeSnapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: HomeDataSource!

    private var selectedRoom: Room?
    private var otherUserData: ChatMember?
    private var selectedCell: RoomDisplayCell?

    var rooms: [Room] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateDataSource()
            }
        }
    }

    @IBOutlet weak var bookingView: BookingView!
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        bookingView.delegate = self

        configureCollectionView()

        fetchRoomsByUserID()
    }

    private func fetchRoomsByUserID() {
        guard let otherUserData = otherUserData else { return }
        FirebaseService.shared.fetchRoomsByUserID(userID: otherUserData.id) { [weak self] rooms in
            guard let `self` = self else { return }
            self.rooms = rooms
        }
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "RoomDisplayCell", bundle: nil),
            forCellWithReuseIdentifier: RoomDisplayCell.identifier)

        dataSource = HomeDataSource(collectionView: collectionView) { collectionView, indexPath, room in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomDisplayCell.identifier,
                for: indexPath) as? RoomDisplayCell else {
                return UICollectionViewCell()
            }

            cell.configureCell(data: room)
            return cell
        }

        collectionView.collectionViewLayout = createLayout()
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - Layout
extension ReservationViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.3))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.3))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Snapshot
extension ReservationViewController {
    private func updateDataSource() {
        var newSnapshot = HomeSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(rooms, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension ReservationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let room = dataSource.itemIdentifier(for: indexPath)
        else { return }
        selectedRoom = room
        updateDataSource()
    }
}

// MARK: - UICollectionViewDelegate
extension ReservationViewController: BookingViewDelegate {
    func didSendRequest(date: DateComponents, selectPeriod: BookingPeriod) {
        guard
            let selectedRoom = selectedRoom,
            let otherUserData = otherUserData else {
            return
        }

//        ReservationService.shared.upsertReservationData(
//            status: AcceptedStatus.waiting.description,
//            room: selectedRoom,
//            sender: ChatMember(
//                id: gCurrentUser.id,
//                profilePhoto: gCurrentUser.profilePhoto,
//                name: gCurrentUser.name),
//            receiver: otherUserData
//        )
    }
}
