//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import UIKit

class PostViewController: UIViewController {
    
    private var room: Room?
    private var roomSpecList: [RoomSpec] = [RoomSpec()] {
        didSet {
            postTableView.reloadData()
        }
    }

    private var county: String?
    private var town: String?

    @IBOutlet weak var regionTextField: UITextField! {
        didSet {
            test()
        }
    }

    @IBOutlet weak var postTableView: UITableView!

    lazy var regionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("請選擇縣市區域", for: .normal)
        button.backgroundColor = .blue
        button.addTarget(self, action: #selector(showRegionPickerPage), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        postTableView.dataSource = self
        postTableView.register(
            UINib(nibName: PostBasicInfoTableViewCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: PostBasicInfoTableViewCell.reuseIdentifier
        )
        postTableView.register(
            UINib(nibName: RoomSpecTableViewCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: RoomSpecTableViewCell.reuseIdentifier
        )
    }

    func test() {
        regionTextField.addSubview(regionButton)
        NSLayoutConstraint.activate([
            regionButton.widthAnchor.constraint(equalTo: regionTextField.widthAnchor),
            regionButton.heightAnchor.constraint(equalTo: regionTextField.heightAnchor),
            regionButton.centerXAnchor.constraint(equalTo: regionTextField.centerXAnchor),
            regionButton.centerYAnchor.constraint(equalTo: regionTextField.centerYAnchor)
        ])
    }

    @objc private func showRegionPickerPage() {
        let regionPickerVC = RegionPickerViewController()
        regionPickerVC.completion = { [weak self] county, town in
            self?.county = county
            self?.town = town

            self?.regionButton.setTitle("\(county)\(town)", for: .normal)
        }
        present(regionPickerVC, animated: true)
    }
}

extension PostViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? roomSpecList.count : 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PostBasicInfoTableViewCell.reuseIdentifier, for: indexPath) as? PostBasicInfoTableViewCell else {
                fatalError("PostBasicInfoTableViewCell Error")
            }
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RoomSpecTableViewCell.reuseIdentifier, for: indexPath) as? RoomSpecTableViewCell else {
                fatalError("RoomSpecTableViewCell Error")
            }
            if indexPath.item == 0 {
                cell.configureLayout(deleteIsHidden: true, addIsHidden: false, data: roomSpecList[indexPath.item])
            } else {
                cell.configureLayout(deleteIsHidden: false, addIsHidden: false, data: roomSpecList[indexPath.item])
            }
            
            cell.delegate = self
//            let roomSpec = RoomSpec()
//            cell.roomSpec = roomSpec
//            roomSpecList.append(roomSpec)
            cell.addColumnAction = { [weak self] cell in
                guard let `self` = self,
                      let indexPath = tableView.indexPath(for: cell) else { return }

                let roomSpec = RoomSpec()
                self.roomSpecList.insert(roomSpec, at: indexPath.item + 1)
                print(self.roomSpecList)

            }

            cell.delectColumnAction = { [weak self] cell in
                guard let `self` = self,
                      let indexPath = tableView.indexPath(for: cell) else { return }
                
                self.roomSpecList.remove(at: indexPath.item)
                print(self.roomSpecList)

            }
            return cell
        }
    }
}

extension PostViewController: RoomSpecTableViewCellDelegate {
    func didChangeData(_ cell: RoomSpecTableViewCell, data: RoomSpec) {
        guard let indexPath = postTableView.indexPath(for: cell) else { return }
        
        roomSpecList[indexPath.item] = data
        print(roomSpecList)
        
    }
}
