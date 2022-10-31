//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

enum PostSection: CaseIterable {
    case basic
    case roomSpec
    case otherFee
    case other
    case rulesHeader
    case rules
    case amenitiesHeader
    case amenities
    case images
}

class PostViewController: UIViewController  {
    private var roomSpecList: [RoomSpec] = [RoomSpec()] {
        didSet {
            collectionView.reloadData()
        }
    }
    var ruleSelection: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var amenitiesSelection: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var waitForUpdateCell: PostImageCell?
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = configureLayout()
        collectionView.register(
            UINib(nibName: PostBasicCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: PostBasicCell.reuseIdentifier
        )
        collectionView.register(
            UINib(nibName: RoomSpecCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: RoomSpecCell.reuseIdentifier
        )
        collectionView.register(
            UINib(nibName: OtherFeeCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: OtherFeeCell.reuseIdentifier
        )
        collectionView.register(
            UINib(nibName: PostImageCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: PostImageCell.reuseIdentifier
        )
        collectionView.register(
            UINib(nibName: RulesCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: RulesCell.reuseIdentifier
        )
        collectionView.register(
            UINib(nibName: RulesHeaderCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: RulesHeaderCell.reuseIdentifier
        )
    }
}

extension PostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItems: Int
        switch PostSection.allCases[section] {
        case .roomSpec:
            numberOfItems = roomSpecList.count
        case .basic, .otherFee, .rulesHeader, .amenitiesHeader:
            numberOfItems = 1
        case .other:
            numberOfItems = 0
        case .images:
            numberOfItems = 5
        case .rules:
            numberOfItems = ruleSelection.count
        case .amenities:
            numberOfItems = amenitiesSelection.count
        }
        return numberOfItems
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        PostSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch PostSection.allCases[indexPath.section] {
        case .basic:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostBasicCell.reuseIdentifier, for: indexPath) as? PostBasicCell else {
                fatalError("PostBasicCell Error")
            }
            cell.delegate = self
            return cell
        case .roomSpec:
            return makeRoomSpecCell(collectionView: collectionView, indexPath: indexPath)
        case .otherFee:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OtherFeeCell.reuseIdentifier, for: indexPath) as? OtherFeeCell else {
                fatalError("PostBasicCell Error")
            }
//            cell.completion = { _ in
//                let regionPickerVC = RegionPickerViewController()
//                regionPickerVC.completion = { county, town in
//                    cell.county = county
//                    cell.town = town
//                }
//                present(regionPickerVC, animated: true)
//
//            }
//            cell.delegate = self
            return cell
        case .other:
            return UICollectionViewCell()
        case .images:
            return makePostImageCell(collectionView: collectionView, indexPath: indexPath)
        case .rules:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RulesCell.reuseIdentifier, for: indexPath) as? RulesCell else {
                fatalError("RulesCell Error")
            }
            let title = ruleSelection[indexPath.item]
            cell.layoutCell(title: title)
            return cell
        case .rulesHeader:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RulesHeaderCell.reuseIdentifier, for: indexPath) as? RulesHeaderCell else {
                fatalError("RulesHeaderCell Error")
            }
            cell.editAction.tag = 1
            cell.editAction.addTarget(self, action: #selector(showMultiChoosePage), for: .touchUpInside)
            cell.titleLabel.text = "Rules"
            return cell
        case .amenitiesHeader:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RulesHeaderCell.reuseIdentifier, for: indexPath) as? RulesHeaderCell else {
                fatalError("RulesHeaderCell Error")
            }
            cell.editAction.tag = 2
            cell.editAction.addTarget(self, action: #selector(showMultiChoosePage), for: .touchUpInside)
            cell.titleLabel.text = "Amenities"
            return cell
        case .amenities:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RulesCell.reuseIdentifier, for: indexPath) as? RulesCell else {
                fatalError("RulesCell Error")
            }
            let title = amenitiesSelection[indexPath.item]
            cell.layoutCell(title: title)
            return cell
        }
    }

    private func makeRoomSpecCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RoomSpecCell.reuseIdentifier,
            for: indexPath
        ) as? RoomSpecCell else {
            fatalError("RoomSpecCell Error")
        }

        cell.delegate = self
        cell.configureLayout(roomSpec: roomSpecList[indexPath.item], indexPath: indexPath)

        cell.addColumnAction = { [weak self] cell in
            guard
                let `self` = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }
            let roomSpec = RoomSpec()
            self.roomSpecList.insert(roomSpec, at: indexPath.item + 1)
            print(self.roomSpecList)
        }

        cell.delectColumnAction = { [weak self] cell in
            guard
                let `self` = self,
                let indexPath = collectionView.indexPath(for: cell) else { return }

            self.roomSpecList.remove(at: indexPath.item)
            print(self.roomSpecList)
        }
        return cell
    }

    private func makePostImageCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PostImageCell.reuseIdentifier,
            for: indexPath
        ) as? PostImageCell else {
            fatalError("PostImageCell Error")
        }
        cell.delegate = self
        return cell
    }
}

extension PostViewController: UICollectionViewDelegate {
    @objc func showMultiChoosePage(_ sender: UIButton) {
        let mutlipleChooseVC = MutlipleChooseController()

        let pageType: MutlipleChooseType = sender.tag == 1 ? .rule : .amenities
        let selectedOptions = sender.tag == 1 ? ruleSelection : amenitiesSelection

        mutlipleChooseVC.initVC(pageType: pageType, selectedOptions: selectedOptions)
        mutlipleChooseVC.completion = { [self] selectedItem in
            if sender.tag == 1 {
                ruleSelection = selectedItem
            } else {
                amenitiesSelection = selectedItem
            }
        }
        present(mutlipleChooseVC, animated: true)
    }
}

extension PostViewController {
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout{ sectionIndex, _ in
//            guard let `self` = self else { return nil }
            switch PostSection.allCases[sectionIndex] {
            case .images:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .absolute(250))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                return section
            case .rules:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(50))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(300))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(300))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section
            }
        }
    }
}

extension PostViewController: PostBasicCellDelegate {
    func showRegionPickerView(cell: PostBasicCell) {
        cell.regionSelectView.resignFirstResponder()
        let regionPickerVC = RegionPickerViewController()
        regionPickerVC.completion = { county, town in
            cell.county = county
            cell.town = town
        }
        present(regionPickerVC, animated: true)
    }
}

extension PostViewController: RoomSpecCellDelegate {
    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        roomSpecList[indexPath.item] = data
        print(roomSpecList)
    }
}

extension PostViewController: PostImageCellDelegate {
    func didClickImageView(_ cell: PostImageCell) {
        waitForUpdateCell = cell
        //         建立一個 UIImagePickerController 的實體
        let imagePickerController = UIImagePickerController()
        
        // 委任代理
        imagePickerController.delegate = self
        
        // 建立一個 UIAlertController 的實體
        // 設定 UIAlertController 的標題與樣式為 動作清單 (actionSheet)
        let imagePickerAlertController = UIAlertController(title: "上傳圖片", message: "請選擇要上傳的圖片", preferredStyle: .actionSheet)
        
        // 建立三個 UIAlertAction 的實體
        // 新增 UIAlertAction 在 UIAlertController actionSheet 的 動作 (action) 與標題
        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { _ in
            
            // 判斷是否可以從照片圖庫取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.photoLibrary)，並 present UIImagePickerController
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { _ in
            
            // 判斷是否可以從相機取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.camera)，並 present UIImagePickerController
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        // 新增一個取消動作，讓使用者可以跳出 UIAlertController
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }
        
        // 將上面三個 UIAlertAction 動作加入 UIAlertController
        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)
        
        // 當使用者按下 uploadBtnAction 時會 present 剛剛建立好的三個 UIAlertAction 動作與
        present(imagePickerAlertController, animated: true, completion: nil)
    }
}

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("===", #function)
        

        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {

            waitForUpdateCell?.imageView.image = pickedImage
        }
        picker.dismiss(animated: true)
    }
}
