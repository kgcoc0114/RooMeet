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

    enum EntryPage {
        case fav
        case ownPost
    }

    typealias FavoriteDataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias FavoriteSnapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: FavoriteDataSource!

    var rooms: [Room] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.collectionView.stopPullToRefresh()
                self.updateDataSource()
                self.noneLabel.isHidden = !self.rooms.isEmpty
                self.goHomeButton.isHidden = self.noneLabel.isHidden
            }
        }
    }

    var user: User?

    var favoriteRooms: [FavoriteRoom] = []

    var entryPage: EntryPage = .fav

    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.isHidden = true
        }
    }

    @IBOutlet weak var goHomeButton: UIButton! {
        didSet {
            goHomeButton.addTarget(self, action: #selector(goHomeAction), for: .touchUpInside)
            goHomeButton.backgroundColor = .mainLightColor
            goHomeButton.tintColor = .mainDarkColor
            goHomeButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            goHomeButton.titleLabel?.font = UIFont.regularText()
            goHomeButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        }
    }

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.title = entryPage == .fav ? "Favorites" : "My Post"
        noneLabel.text = entryPage == .fav ? "按下愛心加入我的最愛" : "還沒有貼文唷！可到首頁新增房源找室友！"
        goHomeButton.setTitle(entryPage == .fav ? "去逛逛" : "新增房源", for: .normal)

        collectionView.delegate = self

        configureCollectionView()
    }

    init(entryPage: EntryPage) {
        super.init(nibName: "FavoritesViewController", bundle: nil)

        self.entryPage = entryPage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchRooms()
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "RoomDisplayCell", bundle: nil),
            forCellWithReuseIdentifier: RoomDisplayCell.identifier)

        dataSource = FavoriteDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, room in
            guard
                let self = self,
                let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomDisplayCell.identifier,
                for: indexPath) as? RoomDisplayCell else {
                return UICollectionViewCell()
            }

            cell.configureCell(data: room)
            cell.isLike = true
            cell.likeButton.isHidden = self.entryPage == .ownPost
            cell.delegate = self
            return cell
        }

        collectionView.collectionViewLayout = createLayout()

        collectionView.addPullToRefresh {[weak self] in
            guard let self = self else { return }
            self.fetchRooms()
        }
    }

    private func fetchRooms() {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else { return }
            self.user = user
        }

        if entryPage == .fav {
            FirebaseService.shared.fetchFavoriteRoomsByUserID(userID: UserDefaults.id) { [weak self] rooms, favoriteRooms in
                guard let self = self else { return }
                self.rooms = rooms
                self.favoriteRooms = favoriteRooms
            }
        } else {
            FirebaseService.shared.fetchRoomsByUserID(userID: UserDefaults.id) { [weak self] rooms in
                guard let self = self else { return }
                self.rooms = rooms
            }
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }

    @objc private func goHomeAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.entryPage == .ownPost {
                let postViewController = PostViewController(entryType: .new, data: nil)
                self.navigationController?.pushViewController(postViewController, animated: true)
            } else {
                self.navigationController?.tabBarController?.selectedIndex = 0
            }
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
            let room = dataSource.itemIdentifier(for: indexPath)
        else { return }
        if entryPage == .fav {
            let detailViewController = RoomDetailViewController(room: room, user: user)
            navigationController?.pushViewController(detailViewController, animated: true)
        } else {
            let postViewController = PostViewController(entryType: .edit, data: room)
            navigationController?.pushViewController(postViewController, animated: true)
        }
    }
}

extension FavoritesViewController: RoomDisplayCellDelegate {
    func didClickedLike(_ cell: RoomDisplayCell, like: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        let updateFavRooms = favoriteRooms.filter { $0.roomID != rooms[indexPath.item].roomID }
        let updateRooms = rooms.filter { $0.roomID != rooms[indexPath.item].roomID }
        rooms = updateRooms
        FirebaseService.shared.updateUserFavoriteRoomsData(favoriteRooms: updateFavRooms)
    }
}
