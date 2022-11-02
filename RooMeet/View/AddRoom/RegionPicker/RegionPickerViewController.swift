//
//  RegionPickerViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class RegionPickerViewController: UIViewController {
    lazy var countyTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(
            UINib(nibName: RegionPickerCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: RegionPickerCell.reuseIdentifier
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    var completion: ((String, String) -> Void)?

    lazy var townTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(
            UINib(nibName: RegionPickerCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: RegionPickerCell.reuseIdentifier
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let regionList: [Region] = Region.regionList
    private var countySelectedIndex: Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        configureHierarchy()
    }

    private func configureHierarchy() {
        view.addSubview(countyTableView)
        view.addSubview(townTableView)
        viewLayout()
    }

    private func  viewLayout() {
        NSLayoutConstraint.activate([
            countyTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            countyTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            countyTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            countyTableView.widthAnchor.constraint(equalToConstant: 100),

            townTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            townTableView.leadingAnchor.constraint(equalTo: countyTableView.trailingAnchor),
            townTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            townTableView.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
}

extension RegionPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == countyTableView {
            return regionList.count
        } else {
            guard let countySelected = countySelectedIndex else {
                return 0
            }
            return regionList[countySelected].town.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RegionPickerCell.reuseIdentifier,
            for: indexPath) as? RegionPickerCell
        else {
            fatalError("Create RegionPickerCell error")
        }
        if tableView == countyTableView {
            cell.regionLabel.text = regionList[indexPath.row].county
        } else {
            if let countySelectedIndex = countySelectedIndex {
                cell.regionLabel.text = regionList[countySelectedIndex].town[indexPath.item]
            }
        }
        return cell
    }
}

extension RegionPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == countyTableView {
            countySelectedIndex = indexPath.item
            townTableView.reloadData()
        } else {
            if let countySelectedIndex = countySelectedIndex {
                let selectedRegion = regionList[countySelectedIndex]
                completion?(selectedRegion.county, selectedRegion.town[indexPath.item])
                dismiss(animated: true)
            }
        }
    }
}
