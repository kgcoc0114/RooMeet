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

    var user: User?

    lazy var reservationAnimationView = RMLottie.shared.reservationAnimationView

    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Reservations"


        collectionView.delegate = self

        configureCollectionView()

        configureAnimationView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else { return }
            self.user = user
        }

        fetchReservations()
        RMLottie.shared.startAnimate(animationView: reservationAnimationView)
    }

    deinit {
        print("=== ProfileRSVNViewController deinit")
    }

    private func configureAnimationView() {
        animationView.addSubview(reservationAnimationView)

        NSLayoutConstraint.activate([
            reservationAnimationView.widthAnchor.constraint(equalTo: animationView.widthAnchor),
            reservationAnimationView.heightAnchor.constraint(equalTo: animationView.heightAnchor),
            reservationAnimationView.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            reservationAnimationView.centerYAnchor.constraint(equalTo: animationView.centerYAnchor)
        ])
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

            cell.configureCell(data: reservation)
            return cell
        }

        collectionView.collectionViewLayout = createLayout()

        collectionView.addPullToRefresh {[weak self] in
            self?.fetchReservations()
        }
    }

    private func fetchReservations() {
        print(UserDefaults.id)
        FirebaseService.shared.fetchReservationRoomsByUserID(userID: UserDefaults.id) { [weak self] reservations in
            self?.reservations = reservations
        }
    }
}

// MARK: - Layout
extension ProfileRSVNViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180))
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
        let detailViewController = RoomDetailViewController(room: reservation.roomDetail!, user: user)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
