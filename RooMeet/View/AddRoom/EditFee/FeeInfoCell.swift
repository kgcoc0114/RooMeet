//
//  FeeInfoCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/1.
//

import UIKit

enum FeeType: String, CaseIterable {
    case electricity = "電費"
    case water = "水費"
    case cable = "第四臺"
    case internet = "網路"
    case management = "管理費"

    func isGovString() -> String {
        var isGovString: String
        switch self {
        case .water:
            isGovString = "台水"
        case .electricity:
            isGovString = "台電"
        case .cable, .internet, .management:
            isGovString = ""
        }
        return isGovString
    }

    func priceUnit() -> String {
        var priceUnit: String
        switch self {
        case .water:
            priceUnit = "元/人"
        case .electricity:
            priceUnit = "元/度"
        case .cable, .internet, .management:
            priceUnit = "元"
        }
        return priceUnit
    }
}

protocol FeeInfoCellDelegate: AnyObject {
    func passData(_ cell: FeeInfoCell)
}

class FeeInfoCell: UITableViewCell {
    static let reuseIdentifier = "\(FeeInfoCell.self)"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var govTypeButton: UIButton!
    @IBOutlet weak var priceTextField: RMBaseTextField!
    @IBOutlet weak var priceUnitLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var sperateButton: UIButton!

    var feeType: FeeType?
    var affordType: AffordType?
    var feeDetail: FeeDetail = FeeDetail() {
        didSet {
            feeDetail.paid = true
        }
    }
    weak var delegate: FeeInfoCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        priceTextField.keyboardType = .numbersAndPunctuation
        priceTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func initialView(feeType: FeeType) {
        self.feeType = feeType
        titleLabel.text = feeType.rawValue
        priceUnitLabel.text = feeType.priceUnit()

        switch feeType {
        case .water, .electricity:
            govTypeButton.setTitle(feeType.isGovString(), for: .normal)
        case .cable, .internet, .management:
            govTypeButton.isHidden = true
        }
    }

    @IBAction func tapSperateButton(_ sender: Any) {
        print("=======")
        print(#function)
        if affordType == .sperate && sperateButton.isSelected == true {
            sperateButton.isSelected.toggle()
        } else {
            sperateButton.isSelected.toggle()
            shareButton.isSelected = !sperateButton.isSelected
        }
        affordType = .sperate

        guard let affordType = affordType else { return }
        feeDetail.affordType = affordType.rawValue
        delegate?.passData(self)
    }

    @IBAction func tapShareButton(_ sender: Any) {
        print("=======")
        print(#function)
        if affordType == .share && shareButton.isSelected == true {
            shareButton.isSelected.toggle()
        } else {
            shareButton.isSelected.toggle()
            sperateButton.isSelected = !shareButton.isSelected
        }
        affordType = .share

        guard let affordType = affordType else { return }
        feeDetail.affordType = affordType.rawValue
        delegate?.passData(self)
    }

    @IBAction func tapGovTypeButton(_ sender: Any) {
        print("=======")
        print(#function)
        govTypeButton.isSelected.toggle()
        feeDetail.isGov = govTypeButton.isSelected
        delegate?.passData(self)
    }
}

extension FeeInfoCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let fee = priceTextField.text {
            feeDetail.fee = Double(fee)
            delegate?.passData(self)
        }
    }
}
