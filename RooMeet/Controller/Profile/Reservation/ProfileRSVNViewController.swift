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
                guard let self = self else { return }
                self.collectionView.stopPullToRefresh()
                self.updateDataSource()
                self.noneLabel.isHidden = !self.reservations.isEmpty
            }
        }
    }

    var user: User?

    lazy var reservationAnimationView = RMLottie.shared.reservationAnimationView

    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.text = "目前沒有看房預約唷！"
            noneLabel.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Reservations"

        collectionView.delegate = self

        configureCollectionView()

        configureAnimationView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
            guard let self = self else { return }
            self.fetchReservations()
        }
    }

    private func fetchReservations() {
        print(UserDefaults.id)
        FirebaseService.shared.fetchReservationRoomsByUserID(userID: UserDefaults.id) { [weak self] reservations, user in
            guard let self = self else { return }
            self.user = user
            self.reservations = reservations
            print(user.reservations)
        }
    }
}

// MARK: - Layout
extension ProfileRSVNViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(170))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(170))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Snapshot
extension ProfileRSVNViewController {
    private func updateDataSource() {
        var newSnapshot = ProfileRSVNSnapshot()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(reservations, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension ProfileRSVNViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(
            identifier: "\(indexPath.item)" as NSCopying,
            previewProvider: nil) { _ in
                let reservation = self.reservations[indexPath.item]

                let agreeMenu = UIAction(
                    title: "同意預約邀請",
                    image: UIImage(systemName: "checkmark.circle"),
                    identifier: nil
                ) { [weak self] _ in
                    guard let self = self else { return }
//                    ReservationService.shared.upsertReservationData(status: .accept, reservation: reservation)
                    ReservationService.shared.replyReservation(reservation: reservation, status: .accept, requestUserID: UserDefaults.id) { error in
                        if error != nil {
                            RMProgressHUD.showFailure(text: "更新狀態有誤")
                        } else {
                            self.updateDataSource()
                        }
                    }
                }

                let rejectMenu = UIAction(
                    title: "拒絕預約邀請",
                    image: UIImage(systemName: "xmark.circle"),
                    identifier: UIAction.Identifier(rawValue: "view")
                ) { [weak self] _ in
                    guard let self = self else { return }
//                    ReservationService.shared.upsertReservationData(status: .cancel, reservation: reservation)
                    ReservationService.shared.replyReservation(reservation: reservation, status: .cancel, requestUserID: UserDefaults.id) { error in
                        if error != nil {
                            RMProgressHUD.showFailure(text: "更新狀態有誤")
                        } else {
                            self.reservations.remove(at: indexPath.item)
                        }

                    }
                }

                let cancelMenu = UIAction(
                    title: "取消預約",
                    image: UIImage(systemName: "c.circle"),
                    identifier: nil
                ) { [weak self] _ in
                    guard let self = self else { return }
//                    let reservation = self.reservations[indexPath.item]
                    ReservationService.shared.replyReservation(reservation: reservation, status: .cancel, requestUserID: UserDefaults.id) { error in
                        if error != nil {
                            RMProgressHUD.showFailure(text: "更新狀態有誤")
                        } else {
                            self.reservations.remove(at: indexPath.item)
                        }

                    }
                }

                var actions: [UIAction]

                if reservation.acceptedStatus == "waiting" && reservation.sender != UserDefaults.id {
                    actions = [agreeMenu, rejectMenu]
                } else {
                    actions = [cancelMenu]
                }

                return UIMenu(title: "", image: nil, identifier: nil, children: actions)
            }
        return config
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let reservation = dataSource.itemIdentifier(for: indexPath),
            let roomDetail = reservation.roomDetail
        else { return }
        let detailViewController = RoomDetailViewController(room: roomDetail, user: user)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

//extension ProfileRSVNViewController: ReservationDisplayCellDelegate {
//    func didCancelReservation(_ cell: ReservationDisplayCell) {
//        guard let indexPath = collectionView.indexPath(for: cell) else {
//            return
//        }
//
//        let reservation = reservations[indexPath.item]
//
//        let alertController = UIAlertController(title: "取消預約", message: "確定要取消預約嗎？", preferredStyle: .actionSheet)
//
//        let deleteAction = UIAlertAction(title: "取消預約", style: .destructive) { [unowned self] _ in
//            ReservationService.shared.replyReservation(reservation: reservation, status: .cancel, requestUserID: UserDefaults.id)
//            reservations.remove(at: indexPath.item)
//        }
//
//        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
//            alertController.dismiss(animated: true)
//        }
//
//        alertController.addAction(deleteAction)
//        alertController.addAction(cancelAction)
//
//        present(alertController, animated: true)
//    }
//}
//
