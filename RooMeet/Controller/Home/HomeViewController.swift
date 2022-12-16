//
//  HomeViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit

class HomeViewController: UIViewController {
    enum Section {
        case main
        case guess
    }

    typealias HomeDataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias HomeSnapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: HomeDataSource!

    var rooms: [Room] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.collectionView.stopPullToRefresh()
                self.updateDataSource()
                self.noneLabel.isHidden = !self.rooms.isEmpty
            }
        }
    }

    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.text = NoDataDisplay.home.displayString
            noneLabel.isHidden = true
        }
    }

    var user: User?

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.plus),
            style: .plain,
            target: self,
            action: #selector(addRoomPost))

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.settings_sliders),
            style: .plain,
            target: self,
            action: #selector(showFilterPage))

        // set title
        navigationItem.title = "RooMeet"

        collectionView.delegate = self

        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)


        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else { return }
            self.user = user
            self.fetchRooms()
        }
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "RoomCell", bundle: nil),
            forCellWithReuseIdentifier: RoomCell.identifier)

        dataSource = HomeDataSource(collectionView: collectionView) { collectionView, indexPath, room in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RoomCell.identifier,
                for: indexPath) as? RoomCell else {
                return UICollectionViewCell()
            }

            cell.configureCell(data: room)
            return cell
        }

        collectionView.collectionViewLayout = createLayout()

        collectionView.addPullToRefresh { [weak self] in
            guard let self = self else { return }
            self.fetchRooms()
        }
    }

    private func fetchRooms() {
        FIRRoomService.shared.fetchRooms(user: self.user) { [weak self] rooms in
            guard let self = self else { return }
            self.rooms = rooms
        }
    }

    @objc private func addRoomPost(_ sender: Any) {
        if AuthService.shared.isLogin() {
            let postViewController = PostViewController(entryType: .new, data: nil)
            navigationController?.pushViewController(postViewController, animated: true)
        } else {
            let loginVC = UIStoryboard.main.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self)
            )
            loginVC.modalPresentationStyle = .overFullScreen
            present(loginVC, animated: false)
        }
    }

    @objc private func showFilterPage() {
        guard let user = user else {
            return
        }

        guard let filterVC = storyboard?.instantiateViewController(
            withIdentifier: "FilterViewController") as? FilterViewController else {
            print("ERROR: FilterViewController Error")
            return
        }

        filterVC.blockUserIDs = user.blocks ?? []

        filterVC.completion = { query in
            FIRRoomService.shared.fetchRoomDataByQuery(user: user, query: query) { rooms in
                self.rooms = rooms
            }
        }
        filterVC.modalPresentationStyle = .overCurrentContext
        present(filterVC, animated: false)
    }
}

// MARK: - Layout
extension HomeViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(300))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Snapshot
extension HomeViewController {
    private func updateDataSource() {
        var newSnapshot = HomeSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(rooms, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let room = dataSource.itemIdentifier(for: indexPath)
        else { return }
        let detailViewController = RoomDetailViewController(room: room, user: user)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
