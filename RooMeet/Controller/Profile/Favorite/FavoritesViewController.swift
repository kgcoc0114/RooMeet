//
//  FavoritesViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

class FavoritesViewController: UIViewController {
    enum Section {
        case main
    }

    typealias FavoriteDataSource = UICollectionViewDiffableDataSource<Section, FavoriteRoom>
    typealias FavoriteSnapshot = NSDiffableDataSourceSnapshot<Section, FavoriteRoom>
    private var dataSource: FavoriteDataSource!

    var rooms: [FavoriteRoom] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.stopPullToRefresh()
                self?.updateDataSource()
            }
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Favorites"

        collectionView.delegate = self

        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchRooms()
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "RoomDisplayCell", bundle: nil),
            forCellWithReuseIdentifier: RoomDisplayCell.identifier)

        dataSource = FavoriteDataSource(collectionView: collectionView) { collectionView, indexPath, favRoom in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomDisplayCell.identifier,
                for: indexPath) as? RoomDisplayCell,
                let room = favRoom.room else {
                return UICollectionViewCell()
            }

            cell.configureCell(data: room)
            cell.isLike = true
            cell.delegate = self
            return cell
        }

        collectionView.collectionViewLayout = createLayout()

        collectionView.addPullToRefresh {[weak self] in
            self?.fetchRooms()
        }
    }

    private func fetchRooms() {
        FirebaseService.shared.fetchFavoriteRoomsByUserID(userID: UserDefaults.id) { [weak self] rooms in
            guard let self = self else { return }
            self.rooms = rooms
        }
    }
}

// MARK: - Layout
extension FavoritesViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(130))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Snapshot
extension FavoritesViewController {
    private func updateDataSource() {
        var newSnapshot = FavoriteSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(rooms, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let favRoom = dataSource.itemIdentifier(for: indexPath),
            let room = favRoom.room
        else { return }
        let detailViewController = RoomDetailViewController(room: room)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension FavoritesViewController: RoomDisplayCellDelegate {
    func didClickedLike(_ cell: RoomDisplayCell, like: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }

        rooms.remove(at: indexPath.item)

        gCurrentUser.favoriteRooms.remove(at: indexPath.item)

        FirebaseService.shared.updateUserFavoriteRoomsData(favoriteRooms: gCurrentUser.favoriteRooms)
    }
}
