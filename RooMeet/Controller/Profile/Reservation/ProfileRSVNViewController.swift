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

    private let viewModel = ReservationViewModel()

    var reservations: [Reservation] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.collectionView.stopPullToRefresh()
                self.updateDataSource()
                self.noneLabel.isHidden = !self.reservations.isEmpty
                self.goHomeButton.isHidden = !self.reservations.isEmpty
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
            noneLabel.text = NoDataDisplay.reservation.displayString
            noneLabel.isHidden = true
        }
    }

    @IBOutlet weak var goHomeButton: UIButton! {
        didSet {
            goHomeButton.isHidden = true
            goHomeButton.setTitle("去逛逛", for: .normal)
            goHomeButton.addTarget(self, action: #selector(goHomeAction), for: .touchUpInside)
            goHomeButton.backgroundColor = .mainLightColor
            goHomeButton.tintColor = .mainDarkColor
            goHomeButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            goHomeButton.titleLabel?.font = UIFont.regularText()
            goHomeButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Reservations"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        configureDataBinding()

        collectionView.delegate = self

        configureCollectionView()

        configureAnimationView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        RMLottie.shared.startAnimate(animationView: reservationAnimationView)
    }

    // MARK: - Data Binding
    private func configureDataBinding() {
        viewModel.reservationResults.bind { [weak self] reservations in
            guard let self = self else { return }
            self.reservations = reservations
        }

        viewModel.userResults.bind { [weak self] user in
            guard let self = self else { return }
            self.user = user
        }
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
        collectionView.registerCellWithNib(reuseIdentifier: ReservationDisplayCell.reuseIdentifier, bundle: nil)

        collectionView.collectionViewLayout = createLayout()

        dataSource = ProfileRSVNDataSource(collectionView: collectionView) { collectionView, indexPath, reservation in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReservationDisplayCell.reuseIdentifier,
                for: indexPath) as? ReservationDisplayCell else {
                return UICollectionViewCell()
            }

            cell.configureCell(data: reservation)
            return cell
        }

        collectionView.addPullToRefresh {[weak self] in
            guard let self = self else { return }
            self.viewModel.fetchReservations()
        }
    }

    @objc private func goHomeAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.navigationController?.tabBarController?.selectedIndex = 0
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

// MARK: - Layout
extension ProfileRSVNViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: .fixed(10), trailing: nil, bottom: .fixed(10))

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150))
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
                    ReservationService.shared.replyReservation(
                        reservation: reservation,
                        status: .accept,
                        requestUserID: UserDefaults.id
                    ) { error in
                        if error != nil {
                            RMProgressHUD.showFailure(text: "更新狀態有誤")
                        } else {
                            self.reservations[indexPath.item].acceptedStatus = "accept"
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
                    ReservationService.shared.replyReservation(
                        reservation: reservation,
                        status: .cancel,
                        requestUserID: UserDefaults.id
                    ) { error in
                        if error != nil {
                            RMProgressHUD.showFailure(text: "更新狀態有誤")
                        } else {
                            self.reservations.remove(at: indexPath.item)
                        }
                    }
                }

                let cancelMenu = UIAction(
                    title: "取消預約",
                    image: UIImage(systemName: "xmark.circle"),
                    identifier: nil
                ) { [weak self] _ in
                    guard let self = self else { return }
                    ReservationService.shared.replyReservation(
                        reservation: reservation,
                        status: .cancel,
                        requestUserID: UserDefaults.id
                    ) { error in
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
