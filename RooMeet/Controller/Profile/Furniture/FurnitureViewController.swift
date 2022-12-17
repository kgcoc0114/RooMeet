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

    lazy var imagePicker: ImagePickerManager = {
        return ImagePickerManager(presentationController: self)
    }()

    var waitForUpdateImageCell: FurnitureDetailCell?

    var furniture = Furniture()
    var furnitureImage: UIImage?

    let scenario: FurnitureScenario

    init(scenario: FurnitureScenario) {
        self.scenario = scenario
        self.furniture = scenario.furniture
        super.init(nibName: String(describing: FurnitureViewController.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self

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
        cell.configure(scenario: scenario)
        return cell
    }
}

extension FurnitureViewController: FurnitureDetailCellDelegate {
    func didClickImageView(_ cell: FurnitureDetailCell) {
        waitForUpdateImageCell = cell
        imagePicker.present(from: cell)
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

extension FurnitureViewController {
    @objc private func saveData() {
        furniture.userID = UserDefaults.id
        RMProgressHUD.show()
        if let furnitureImage = furnitureImage {
            FIRStorageService.shared.uploadImage(
                image: furnitureImage,
                path: FIRStorageEndpoint.furnitureImages.path
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
        switch scenario {
        case .create:
            FIRFurnitureService.shared.insertFurniture(furniture: furniture) { error in
                if error != nil {
                    RMProgressHUD.showFailure()
                } else {
                    RMProgressHUD.showSuccess()
                }
                self.navigationController?.popViewController(animated: true)
            }
        case .edit:
            if let furnitureID = furniture.id {
                FIRFurnitureService.shared.updateFurniture(furnitureID: furnitureID, furniture: furniture) { error in
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

// MARK: - Profile Image Picker Delegate
extension FurnitureViewController: ImagePickerManagerDelegate {
    func imagePickerController(didSelect: UIImage?) {
        guard let image = didSelect else { return }
        waitForUpdateImageCell?.photoImageView.image = image
        furnitureImage = image
    }
}
