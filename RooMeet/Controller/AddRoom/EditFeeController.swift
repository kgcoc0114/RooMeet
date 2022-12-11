//
//  EditFeeController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/1.
//

import UIKit

enum EditFeeScenario {
    case create(BillInfo)
    case edit(BillInfo)
}

class EditFeeController: UIViewController {
    @IBOutlet weak var dismissButton: UIButton! {
        didSet {
            dismissButton.setTitle("", for: .normal)
        }
    }
    @IBOutlet weak var confirmButton: UIButton! {
        didSet {
            confirmButton.backgroundColor = UIColor.mainColor
            confirmButton.tintColor = UIColor.mainBackgroundColor
            confirmButton.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "其他費用"
            titleLabel.font = UIFont.regularTitle()
        }
    }

    var completion: ((BillInfo) -> Void)?
    var entryType: EntryType = .new

    var billInfo = BillInfo(
        water: FeeDetail(),
        electricity: FeeDetail(),
        cable: FeeDetail(),
        internet: FeeDetail(),
        management: FeeDetail()
    )

    init(billInfo: BillInfo?) {
        super.init(nibName: String(describing: EditFeeController.self), bundle: nil)
        if let billInfo = billInfo {
            self.billInfo = billInfo
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.registerCellWithNib(identifier: FeeInfoCell.reuseIdentifier, bundle: nil)
    }

    @IBAction func confirmAction(_ sender: Any) {
        self.completion?(billInfo)
        dismiss(animated: true)
    }

    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension EditFeeController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FeeInfoCell.reuseIdentifier,
            for: indexPath) as? FeeInfoCell else {
            fatalError("ERROR: - Create FeeInfoCell ERROR")
        }

        let feeType = FeeType.allCases[indexPath.item]
        var feeDetail = FeeDetail()

        switch feeType {
        case .electricity:
            feeDetail = billInfo.electricity
        case .water:
            feeDetail = billInfo.water
        case .cable:
            feeDetail = billInfo.cable
        case .internet:
            feeDetail = billInfo.internet
        case .management:
            feeDetail = billInfo.management
        }

        cell.configureCell(
            feeType: feeType,
            entryType: entryType,
            data: feeDetail
        )

        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        FeeType.allCases.count
    }
}

extension EditFeeController: FeeInfoCellDelegate {
    func passData(_ cell: FeeInfoCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let feeType = FeeType.allCases[indexPath.item]
        var feeDetail = cell.feeDetail
        if feeDetail.isGov == true || feeDetail.fee == 0 || feeDetail.fee == nil {
            feeDetail.paid = true
        } else {
            feeDetail.paid = false
        }

        switch feeType {
        case .electricity:
            billInfo.electricity = cell.feeDetail
        case .water:
            billInfo.water = cell.feeDetail
        case .cable:
            billInfo.cable = cell.feeDetail
        case .internet:
            billInfo.internet = cell.feeDetail
        case .management:
            billInfo.management = cell.feeDetail
        }
        print(billInfo)
    }
}
