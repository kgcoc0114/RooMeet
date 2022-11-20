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

    @IBOutlet weak var segmentControl: RMSegmentedControl! {
        didSet {
            segmentControl.items = AffordType.allCases.map { $0.description }
            segmentControl.borderColor = UIColor.mainLightColor
            segmentControl.selectedLabelColor = UIColor.mainDarkColor
            segmentControl.unselectedLabelColor = UIColor.mainColor
            segmentControl.backgroundColor = .white
            segmentControl.thumbColor = UIColor.mainLightColor
            segmentControl.selectedIndex = 0
            segmentControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var govTypeButton: FeeButton! {
        didSet {
            govTypeButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius * 0.9
            govTypeButton.isSelected = false
        }
    }
    @IBOutlet weak var priceTextField: RMBaseTextField!
    @IBOutlet weak var priceUnitLabel: UILabel!
//    @IBOutlet weak var shareButton: FeeButton! {
//        didSet {
//            shareButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
//            shareButton.isSelected = false
//        }
//    }
//
//    @IBOutlet weak var sperateButton: FeeButton! {
//        didSet {
//            sperateButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
//            sperateButton.isSelected = false
//        }
//    }

    var feeType: FeeType?
    var affordType: AffordType?
    var feeDetail = FeeDetail() {
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
    }

    func configureCell(feeType: FeeType, entryType: EntryType, data: FeeDetail?) {
        self.feeType = feeType
        titleLabel.text = feeType.rawValue
        priceUnitLabel.text = feeType.priceUnit()

        switch feeType {
        case .water, .electricity:
            govTypeButton.setTitle(feeType.isGovString(), for: .normal)
            if entryType == .edit,
                let data = data,
                let isGov = data.isGov {
                govTypeButton.isSelected = isGov
            }
        case .cable, .internet, .management:
            govTypeButton.isHidden = true
        }

        if entryType == .edit,
            let data = data {
            feeDetail = data
            if feeDetail.paid == true {
                segmentControl.selectedIndex
                = AffordType.allCases.firstIndex(of: AffordType(rawValue: feeDetail.affordType ?? "sperate")!) ?? 0
            }

            if let fee = feeDetail.fee,
                fee != 0 {
                priceTextField.text = "\(fee)"
            }
        }
    }

//    @IBAction func tapSperateButton(_ sender: Any) {
//        if affordType == .sperate && sperateButton.isSelected == true {
//            sperateButton.isSelected.toggle()
//        } else {
//            sperateButton.isSelected.toggle()
//            shareButton.isSelected = !sperateButton.isSelected
//        }
//        affordType = .sperate
//
//        guard let affordType = affordType else { return }
//        feeDetail.affordType = affordType.rawValue
//        delegate?.passData(self)
//    }
//
//    @IBAction func tapShareButton(_ sender: Any) {
//        if affordType == .share && shareButton.isSelected == true {
//            shareButton.isSelected.toggle()
//        } else {
//            shareButton.isSelected.toggle()
//            sperateButton.isSelected = !shareButton.isSelected
//        }
//        affordType = .share
//
//        guard let affordType = affordType else { return }
//        feeDetail.affordType = affordType.rawValue
//        delegate?.passData(self)
//    }

    @IBAction func tapGovTypeButton(_ sender: Any) {
        govTypeButton.isSelected.toggle()
        feeDetail.isGov = govTypeButton.isSelected
        feeDetail.affordType = segmentControl.selectedIndex == 0 ? "sperate" : "share"
        delegate?.passData(self)
    }

    @objc func segmentValueChanged(_ sender: RMSegmentedControl) {
        feeDetail.affordType = sender.selectedIndex == 0 ? "sperate" : "share"
        delegate?.passData(self)
    }
}

extension FeeInfoCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let fee = priceTextField.text {
            feeDetail.fee = Double(fee)
            feeDetail.affordType = segmentControl.selectedIndex == 0 ? "sperate" : "share"
            delegate?.passData(self)
        }
    }
}

class FeeButton: UIButton {
    override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.backgroundColor = UIColor.mainColor
                self.tintColor = UIColor.mainLightColor
            } else {
                self.backgroundColor = UIColor.mainLightColor
                self.tintColor = UIColor.mainColor
            }
        }
    }
}
