//
//  BlockViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/23.
//

import UIKit

class BlockViewController: UIViewController {
    enum Section: String, CaseIterable {
        case main
    }

    enum Item: Hashable {
        case main(User)
    }

    @IBOutlet weak var unlockBackgroundView: UIView!

    @IBOutlet weak var unlockButton: UIButton! {
        didSet {
            unlockButton.isEnabled = false
            unlockButton.backgroundColor = .mainLightColor
            unlockButton.setTitleColor(.mainLightColor, for: .disabled)
            unlockButton.setTitleColor(.mainLightColor, for: .normal)
            unlockButton.layer.borderColor = UIColor.mainLightColor.cgColor
            unlockButton.layer.borderWidth = 0.8
            unlockButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
            unlockButton.setTitle("解除封鎖", for: .normal)
        }
    }

    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.text = NoDataDisplay.blockade.displayString
            noneLabel.isHidden = true
        }
    }

    typealias BlockDataSource = UICollectionViewDiffableDataSource<Section, User>
    typealias BlockSnapshot = NSDiffableDataSourceSnapshot<Section, User>
    private var dataSource: BlockDataSource!

    var users: [User] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateDataSource()
                self.noneLabel.isHidden = !self.users.isEmpty
                self.unlockBackgroundView.isHidden = self.users.isEmpty
            }
        }
    }

    var toBeUnlock: [String] = [] {
        didSet {
            unlockButton.isEnabled = !toBeUnlock.isEmpty
            unlockButton.backgroundColor = unlockButton.isEnabled == true ? .mainColor : .mainLightColor

            unlockButton.layer.borderColor = unlockButton.isEnabled == true
            ? UIColor.mainColor.cgColor
            : UIColor.mainLightColor.cgColor

            DispatchQueue.main.async { [weak self] in
                self?.updateDataSource()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        collectionView.collectionViewLayout = createLayout()

        navigationItem.title = "解除封鎖"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationController?.interactivePopGestureRecognizer?.delegate = nil

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FIRUserService.shared.fatchBlockUsers { [weak self] users, error in
            guard let self = self else { return }
            self.users = users
        }
    }

    @IBAction func unlockAction(_ sender: Any) {
        if !toBeUnlock.isEmpty {
            FIRUserService.shared.deleteBlock(blockedUsers: toBeUnlock)
            RMProgressHUD.showSuccess()
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

// MARK: - CollectionView DataSource
extension BlockViewController {
    private func configureCollectionView() {
        collectionView.register(
            UINib(nibName: "BlockCell", bundle: nil),
            forCellWithReuseIdentifier: BlockCell.reuseIdentifier
        )

        dataSource = BlockDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, user in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: BlockCell.reuseIdentifier,
                    for: indexPath
                ) as? BlockCell
            else {
                return UICollectionViewCell()
            }
            cell.configureCell(data: user)
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - BlockCell Delegate
extension BlockViewController: BlockCellDelegate {
    func didSelectedUnblock(_ cell: BlockCell, isUnBlock: Bool) {
        guard
            let indexPath = collectionView.indexPath(for: cell) else {
            return
        }

        let user = users[indexPath.item]

        if isUnBlock {
            toBeUnlock.append(user.id)
        } else {
            guard let index = toBeUnlock.firstIndex(of: user.id) else {
                return
            }
            if index >= 0 {
                toBeUnlock.remove(at: index)
            }
        }
    }
}

// MARK: - CollectionView Layout
extension BlockViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - CollectionView Snapshot
extension BlockViewController {
    private func updateDataSource() {
        var newSnapshot = BlockSnapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(users, toSection: .main)
        dataSource.apply(newSnapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension BlockViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? BlockCell else {
            return
        }
        cell.unblockbutton.isSelected.toggle()
    }
}
