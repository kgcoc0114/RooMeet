//
//  ProfileRSVNViewController.swift
//  Profile reservation
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

class ProfileRSVNViewController: UIViewController {
    enum Section {
        case main
    }

    typealias ProfileRSVNDataSource = UICollectionViewDiffableDataSource<Section, Reservation>
    typealias ProfileRSVNSnapshot = NSDiffableDataSourceSnapshot<Section, Reservation>
    private var dataSource: ProfileRSVNDataSource!

    var reservations: [Reservation] = [] {
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
        navigationItem.title = "Reservations"

        collectionView.delegate = self

        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        // fetch room to display
        fetchReservations()
    }

    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "ReservationDisplayCell", bundle: nil),
            forCellWithReuseIdentifier: ReservationDisplayCell.identifier)

        dataSource = ProfileRSVNDataSource(collectionView: collectionView) { collectionView, indexPath, reservation in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReservationDisplayCell.identifier,
                for: indexPath) as? ReservationDisplayCell else {
                return UICollectionViewCell()
            }

//            cell.checkImageView.isHidden = true
            cell.configureCell(data: reservation)
            return cell
        }

        collectionView.collectionViewLayout = createLayout()

        collectionView.addPullToRefresh {[weak self] in
            self?.fetchReservations()
        }
    }

    private func fetchReservations() {
        FirebaseService.shared.fetchReservationRoomsByUserID(reservationList: gCurrentUser.reservations) { reservations in
            self.reservations = reservations
        }
    }
}

// MARK: - Layout
extension ProfileRSVNViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Snapshot
extension ProfileRSVNViewController {
    private func updateDataSource() {
        var newSnapshot = ProfileRSVNSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(reservations.map { $0 }, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension ProfileRSVNViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let reservation = dataSource.itemIdentifier(for: indexPath)
        else { return }
        let detailViewController = RoomDetailViewController(room: reservation.roomDetail!)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
