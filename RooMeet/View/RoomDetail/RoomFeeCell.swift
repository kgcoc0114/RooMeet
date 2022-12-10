//
//  RoomFeeCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class RoomFeeCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor.mainDarkColor
            titleLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var affordTypeLabel: UILabel! {
        didSet {
            affordTypeLabel.textColor = UIColor.mainDarkColor
            affordTypeLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var feeLabel: UILabel! {
        didSet {
            feeLabel.textColor = UIColor.mainDarkColor
            feeLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(billType: BillType, data: FeeDetail) {
        iconImageView.image = billType.image
        titleLabel.text = "\(billType.title)"

        if let isGov = data.isGov,
            isGov == true {
            feeLabel.text = "台\(billType.title)"
        } else {
            guard let fee = data.fee else {
                feeLabel.text = ""
                return
            }

            if billType != .electricity {
                feeLabel.text = "$ \(Int(fee)) \(billType.unitString)"
            } else {
                feeLabel.text = "$ \(fee) \(billType.unitString)"
            }
        }

        let separateString = data.affordType == "separate" ? billType.separateString : "總費用均分"

        affordTypeLabel.text = separateString
    }
}

extension RoomFeeCell: RoomDetailCell {
    func configure(container: RoomDetailContainer) {
        guard let roomDetailFee = (container as? FeeDetailContainer)?.roomDetailFee else {
            return
        }

        let billType = roomDetailFee.billType
        let feeDatail = roomDetailFee.feeDatail

        iconImageView.image = billType.image
        titleLabel.text = "\(billType.title)"

        if
            let isGov = feeDatail.isGov,
            isGov == true {
            feeLabel.text = "台\(billType.title)"
        } else {
            guard let fee = feeDatail.fee else {
                feeLabel.text = ""
                return
            }

            if billType != .electricity {
                feeLabel.text = "$ \(Int(fee)) \(billType.unitString)"
            } else {
                feeLabel.text = "$ \(fee) \(billType.unitString)"
            }
        }
        print(feeDatail.affordType)
        let separateString = BillType(rawValue: feeDatail.affordType)?.separateString

        affordTypeLabel.text = separateString
    }
}
