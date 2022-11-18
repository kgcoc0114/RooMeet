//
//  LocationPickerViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/18.
//

import UIKit

class LocationPickerViewController: RMButtomSheetViewController {

    // define lazy views
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "選擇地區"
        label.font = UIFont.bold(size: 18)
        label.textColor = UIColor.main
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var countyTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .mainLightColor
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

    private let regionList: [Region] = LocationService.shared.regionList ?? []
    private var countySelectedIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultHeight = 600
        currentContainerHeight = 600

        setupBaseView()
        setupBaseConstraints()

        configureLayout()
    }

    func configureLayout() {
        containerView.addSubview(titleLabel)
        containerView.addSubview(countyTableView)
        containerView.addSubview(townTableView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countyTableView.translatesAutoresizingMaskIntoConstraints = false
        townTableView.translatesAutoresizingMaskIntoConstraints = false


        // Set static constraints
        NSLayoutConstraint.activate([
            // titleLabel
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            // countyTableView
            countyTableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            countyTableView.trailingAnchor.constraint(equalTo: containerView.centerXAnchor),
            countyTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            countyTableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            // townTableView
            townTableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            townTableView.leadingAnchor.constraint(equalTo: containerView.centerXAnchor),
            townTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            townTableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

extension LocationPickerViewController: UITableViewDataSource {
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
            cell.backgroundColor = UIColor.mainLightColor
            cell.regionLabel.text = regionList[indexPath.row].county
        } else {
            if let countySelectedIndex = countySelectedIndex {
                cell.regionLabel.text = regionList[countySelectedIndex].town[indexPath.item]
            }
        }
        return cell
    }
}

extension LocationPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == countyTableView {
            countySelectedIndex = indexPath.item
            townTableView.reloadData()
        } else {
            if let countySelectedIndex = countySelectedIndex {
                let selectedRegion = regionList[countySelectedIndex]
                completion?(selectedRegion.county, selectedRegion.town[indexPath.item])
                animateDismissView()
            }
        }
    }
}
