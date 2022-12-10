//
//  FurnitureViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class FurnitureViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    lazy var imagePickerController = UIImagePickerController()
    var waitForUpdateImageCell: FurnitureDetailCell?

    var furniture = Furniture()
    var furnitureImage: UIImage?

    var entryType: EntryType = .new

    init(entryType: EntryType, data: Furniture?) {
        super.init(nibName: "FurnitureViewController", bundle: nil)

        self.entryType = entryType
        switch entryType {
        case .edit:
            if let furniture = data {
                self.furniture = furniture
            }
        case .new:
            self.furniture = Furniture()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.registerCellWithNib(identifier: FurnitureDetailCell.identifier, bundle: nil)
        tableView.separatorStyle = .none

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveData)
        )

        navigationItem.title = "Add / Edit"
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

extension FurnitureViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FurnitureDetailCell.identifier,
            for: indexPath) as? FurnitureDetailCell else { return UITableViewCell() }
        cell.delegate = self
        cell.funiture = furniture
        cell.configureCell()
        return cell
    }
}

extension FurnitureViewController: FurnitureDetailCellDelegate {
    func didClickImageView(_ cell: FurnitureDetailCell) {
        imagePickerController.delegate = self
        waitForUpdateImageCell = cell
        let imagePickerAlertController = UIAlertController(
            title: "上傳圖片",
            message: "請選擇要上傳的圖片",
            preferredStyle: .actionSheet
        )

        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.imagePickerController.sourceType = .photoLibrary
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }

        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)

        present(imagePickerAlertController, animated: true, completion: nil)
    }


    func passData(_ cell: FurnitureDetailCell, data: Furniture) {
        self.furniture = data
    }

    func showMeasure(_ cell: FurnitureDetailCell, type: String) {
        let showVC = MeasureViewController()
        showVC.completion = { [weak self] value, valueString in
            guard
                let self = self,
                let value = value,
                let valueString = valueString else {
                return
            }

            switch type {
            case "length":
                self.furniture.length = value
                cell.lengthTextField.text = valueString
            case "width":
                self.furniture.width = value
                cell.widthTextField.text = valueString
            case "height":
                self.furniture.height = value
                cell.heightTextField.text = valueString
            default:
                print("")
            }
        }

        showVC.modalPresentationStyle = .overCurrentContext

        self.hidesBottomBarWhenPushed = true
        DispatchQueue.main.async {
            self.hidesBottomBarWhenPushed = false
        }

        navigationController?.pushViewController(showVC, animated: false)
    }
}

extension FurnitureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {
            furnitureImage = pickedImage
            guard let cell = self.waitForUpdateImageCell else {
                return
            }
            cell.photoImageView.image = pickedImage
        }

        picker.dismiss(animated: true)
    }

    @objc private func saveData() {
        furniture.userID = UserDefaults.id

        RMProgressHUD.show()
        if let furnitureImage = furnitureImage {
            FIRStorageService.shared.uploadImage(
                image: furnitureImage,
                path: "FurnitureImages"
            ) { [weak self] url, error in
                guard let self = self else { return }
                if error != nil {
                    RMProgressHUD.showFailure(text: "上傳圖片有誤")
                } else {
                    self.furniture.imageURL = url?.absoluteString ?? nil
                    self.upsertData()
                }
            }
        } else {
            upsertData()
        }
    }

    private func upsertData() {
        furniture.createdTime = Timestamp()
        if entryType == .new {
            FirebaseService.shared.insertFurniture(furniture: furniture) { error in
                if error != nil {
                    RMProgressHUD.showFailure()
                } else {
                    RMProgressHUD.showSuccess()
                }
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if let furnitureID = furniture.id {
                FirebaseService.shared.updateFurniture(furnitureID: furnitureID, furniture: furniture) { error in
                    if error != nil {
                        RMProgressHUD.showFailure()
                    } else {
                        RMProgressHUD.showSuccess()
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}


extension FurnitureViewController {
    func transToInt(input: String) -> Int? {
        if let outputNumber = Int(input.replace(target: "cm", withString: "")) {
            return outputNumber
        } else {
            return nil
        }
    }
}
