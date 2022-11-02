//
//  EditFeeController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/1.
//

import UIKit

class EditFeeController: UIViewController {

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var completion: ((BillInfo) -> Void)?

    var billInfo: BillInfo = BillInfo(
        water: FeeDetail(),
        electricity: FeeDetail(),
        cable: FeeDetail(),
        internet: FeeDetail(),
        management: FeeDetail()
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: FeeInfoCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: FeeInfoCell.reuseIdentifier
        )
    }

    @IBAction func confirmAction(_ sender: Any) {
        self.completion?(billInfo)
        dismiss(animated: true)
    }
}

extension EditFeeController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeeInfoCell.reuseIdentifier, for: indexPath) as? FeeInfoCell else {
            fatalError()
        }

        let feeType = FeeType.allCases[indexPath.item]
        cell.initialView(feeType: feeType)
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
        var feeType = FeeType.allCases[indexPath.item]
        var feeDetail = cell.feeDetail
        if feeDetail.isGov == true || feeDetail.fee == 0 || feeDetail.fee == nil {
            feeDetail.paid = true
        } else {
            feeDetail.paid = false
        }
        print(feeType)
        print(feeDetail)

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
