//
//  HomeViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit
import MapKit

class HomeViewController: UIViewController {
    enum Section: CaseIterable {
        case rooms
    }

    enum Item: Hashable {
        case chatRoom(ChatRoom)
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: DataSource!

    var rooms: [Room] = [] {
        didSet {
            updateDataSource()
        }
    }

    let locationManger = LocationService.shared.locationManger

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: RoomCardCell.reuseIdentifier, bundle: nil),
                forCellWithReuseIdentifier: RoomCardCell.reuseIdentifier
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // get User Location
        locationManger.delegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self else { return }
            self.locationManger.requestLocation()
        }

        // set title
        navigationItem.title = "RooMeet"

        // set data source & layout
        configureDataSource()
        collectionView.setCollectionViewLayout(createLayout(), animated: false)

        // fetch room to display
        FirebaseService.shared.fetchRooms { [weak self] rooms in
            guard let `self` = self else { return }
            self.rooms = rooms
        }
    }

    @IBAction func addRoomPost(_ sender: Any) {
        let postVC = PostViewController()
        navigationController?.pushViewController(postVC, animated: true)
    }
}

// MARK: Data Source
extension HomeViewController {
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView, cellProvider: { [unowned self] collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoomCardCell.reuseIdentifier, for: indexPath) as? RoomCardCell else {
                return UICollectionViewCell()
            }
            if !self.rooms.isEmpty {
                let room = rooms[indexPath.item]
                cell.configureCell(room: room)
            }
            return cell
        })
    }
}

// MARK: Snapshot
extension HomeViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(rooms.map({ $0 }), toSection: .rooms)
        dataSource.apply(newSnapshot, animatingDifferences: true)
    }
}

// MARK: Layout
extension HomeViewController {
    func createRoomsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.3)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = dataSource.snapshot().sectionIdentifiers[index]

        switch section {
        case .rooms:
            return createRoomsSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] index, env in
            return self.sectionFor(index: index, environment: env)
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let roomDetailVC = RoomDetailViewController()
        navigationController?.pushViewController(roomDetailVC, animated: false)
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print(gCurrentPosition)
            gCurrentPosition = location.coordinate
            print(gCurrentPosition)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
