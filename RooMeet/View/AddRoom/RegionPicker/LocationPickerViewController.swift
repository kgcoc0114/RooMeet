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
        label.textColor = UIColor.mainColor
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

    var completion: ((String, String?) -> Void)?

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
    private var countySelectedIndex: Int = 0
    private var selectedCell: RegionPickerCell?
    private var selectedTown: String?

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
            return regionList[countySelectedIndex].town.count
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
            if countySelectedIndex == indexPath.item {
                cell.isPicked = countySelectedIndex == indexPath.item
                selectedCell = cell
            } else {
                cell.isPicked = false
            }
            cell.regionLabel.text = regionList[indexPath.row].county
        } else {
            cell.regionLabel.text = regionList[countySelectedIndex].town[indexPath.item]
        }
        return cell
    }
}

extension LocationPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == countyTableView {
            countySelectedIndex = indexPath.item
            guard let cell = tableView.cellForRow(at: indexPath) as? RegionPickerCell else {
                return
            }
            if let selectedCell = selectedCell {
                selectedCell.isPicked.toggle()
            }
            cell.isPicked.toggle()
            selectedCell = cell
            selectedTown = nil
            townTableView.reloadData()
        } else {
            let selectedRegion = regionList[countySelectedIndex]
            selectedTown = selectedRegion.town[indexPath.item]
            completion?(selectedRegion.county, selectedTown)
            animateDismissView()
        }
    }
}
