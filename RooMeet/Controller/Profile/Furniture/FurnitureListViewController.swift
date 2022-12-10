//
//  FurnitureListViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import UIKit

class FurnitureListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var furnitures: [Furniture] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.stopPullToRefresh()
                self.tableView.reloadData()

                self.noneLabel.isHidden = !self.furnitures.isEmpty
            }
        }
    }

    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.isHidden = true
            noneLabel.text = NoDataDisplay.furniture.displayString
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.plus),
            style: .plain,
            target: self,
            action: #selector(addFurnitures))

        navigationItem.title = "My Furnitures"
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFurnitures()
    }

    private func fetchFurnitures() {
        FirebaseService.shared.fetchFurnituresByUserID { [weak self] furnitures in
            guard let self = self else { return }
            self.furnitures = furnitures
        }
    }

    @objc private func addFurnitures() {
        showFurnitures(scenario: FurnitureScenario.create(Furniture(userID: UserDefaults.id)))
    }

    private func editFurnitures(furniture: Furniture) {
        showFurnitures(scenario: FurnitureScenario.edit(furniture))
    }

    private func showFurnitures(scenario: FurnitureScenario) {
        let furnitureViewController = FurnitureViewController(scenario: scenario)
        navigationController?.pushViewController(furnitureViewController, animated: true)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.separatorStyle = .none

        tableView.registerCellWithNib(identifier: FurnitureDisplayCell.identifier, bundle: nil)

        tableView.addPullToRefresh { [weak self] in
            guard let self = self else { return }
            self.fetchFurnitures()
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }
}

extension FurnitureListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        furnitures.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FurnitureDisplayCell.identifier,
            for: indexPath) as? FurnitureDisplayCell
        else {
            return FurnitureDisplayCell()
        }
        let furniture = furnitures[indexPath.item]
        cell.configureCell(data: furniture)
        return cell
    }
}

extension FurnitureListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(
            identifier: "\(indexPath.item)" as NSCopying,
            previewProvider: {
                return FurnitureViewController(scenario: FurnitureScenario.edit(self.furnitures[indexPath.item]))
            }) { _ in
                let viewMenu = UIAction(
                    title: "編輯",
                    image: UIImage(systemName: "square.and.pencil"),
                    identifier: UIAction.Identifier(rawValue: "view")
                ) { [weak self] _ in
                    guard let self = self else { return }
                    let furniture = self.furnitures[indexPath.item]
                    self.editFurnitures(furniture: furniture)
                }

                let deleteMenu = UIAction(
                    title: "刪除",
                    image: UIImage(systemName: "trash.fill"),
                    identifier: nil
                ) { [weak self] _ in
                    guard let self = self else { return }
                    let furniture = self.furnitures[indexPath.item]
                    if let furnitureID = furniture.id {
                        self.furnitures.remove(at: indexPath.item)
                        FirebaseService.shared.deleteFurniture(furnitureID: furnitureID) { _ in
                            print("done")
                        }
                    }
                    tableView.reloadData()
                }

            return UIMenu(title: "", image: nil, identifier: nil, children: [viewMenu, deleteMenu])
        }
        return config
    }
}
