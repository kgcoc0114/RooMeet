//
//  HomeViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit
import MapKit

class HomeViewController: UIViewController {
    enum Section {
        case main
    }

    typealias HomeDataSource = UICollectionViewDiffableDataSource<Section, Room>
    typealias HomeSnapshot = NSDiffableDataSourceSnapshot<Section, Room>
    private var dataSource: HomeDataSource!

    let locationManger = LocationService.shared.locationManger
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
        print("===", gCurrentUser.id)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addRoomPost))

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(showFilterPage))

        // get User Location
        locationManger.delegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self else { return }
            self.locationManger.requestLocation()
        }

        // set title
        navigationItem.title = "RooMeet"

        collectionView.delegate = self

        configureCollectionView()

        // fetch room to display
        fetchRooms()
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

        collectionView.addPullToRefresh {[weak self] in
            self?.fetchRooms()
        }
    }

    private func fetchRooms() {
        FirebaseService.shared.fetchRooms { [weak self] rooms in
            guard let `self` = self else { return }
            self.rooms = rooms
        }
    }

    @objc private func addRoomPost(_ sender: Any) {
        let postVC = PostViewController()
        navigationController?.pushViewController(postVC, animated: true)
    }

    @objc private func showFilterPage() {
        guard let filterVC = storyboard?.instantiateViewController(
            withIdentifier: "FilterViewController") as? FilterViewController else {
            print("ERROR: FilterViewController Error")
            return
        }

        filterVC.completion = { query in
            FirebaseService.shared.fetchRoomDatabyQuery(query: query) { rooms in
                self.rooms = rooms
            }
        }
        present(filterVC, animated: true)
    }
}

// MARK: - Layout
extension HomeViewController {
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
extension HomeViewController {
    private func updateDataSource() {
        var newSnapshot = HomeSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(rooms.map { $0 }, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let room = dataSource.itemIdentifier(for: indexPath)
        else { return }
        let detailViewController = RoomDetailViewController(room: room)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            gCurrentPosition = location.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
