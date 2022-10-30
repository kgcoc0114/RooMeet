//
//  PostViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import UIKit

class PostViewController: UIViewController {
    private var room: Room?
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
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostBasicInfoTableViewCell.reuseIdentifier, for: indexPath) as? PostBasicInfoTableViewCell else {
            fatalError("PostBasicInfoTableViewCell Error")
        }
        return cell
    }
}
