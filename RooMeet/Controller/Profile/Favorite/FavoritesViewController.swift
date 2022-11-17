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

    typealias FavoriteDataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias FavoriteSnapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: FavoriteDataSource!

    var rooms: [Room] = [] {
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

//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            image: UIImage(systemName: "plus"),
//            style: .plain,
//            target: self,
//            action: #selector(addRoomPost))
//
//        navigationItem.leftBarButtonItem = UIBarButtonItem(
//            image: UIImage(systemName: "slider.horizontal.3"),
//            style: .plain,
//            target: self,
//            action: #selector(showFilterPage))
        // set title
        navigationItem.title = "Favorites"

        collectionView.delegate = self

        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        // fetch room to display
        fetchRooms()
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "RoomDisplayCell", bundle: nil),
            forCellWithReuseIdentifier: RoomDisplayCell.identifier)

        dataSource = FavoriteDataSource(collectionView: collectionView) { collectionView, indexPath, room in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomDisplayCell.identifier,
                for: indexPath) as? RoomDisplayCell else {
                return UICollectionViewCell()
            }

            cell.checkImageView.isHidden = true
            cell.configureCell(data: room)
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
extension FavoritesViewController {
    private func updateDataSource() {
        var newSnapshot = FavoriteSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(rooms.map { $0 }, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let room = dataSource.itemIdentifier(for: indexPath)
        else { return }
        let detailViewController = RoomDetailViewController(room: room)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
