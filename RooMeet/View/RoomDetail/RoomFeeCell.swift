//
//  RoomFeeCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomFeeCell: UICollectionViewCell {
    static let identifier = "RoomFeeCell"

    var billInfo: BillInfo?

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(data: BillInfo) {
        self.billInfo = data

        if let billInfo = self.billInfo {
            BillType.allCases.forEach { billType in
                let feeDetail = billType.feeDetail(billInfo: billInfo)

                if feeDetail.paid == true {
                    generateDetailStackView(billType: billType, feeDetail: feeDetail)
                }
            }
        }

        self.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            stackView.bottomAnchor.constraint(greaterThanOrEqualTo: self.bottomAnchor, constant: -10),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])

    }

    func generateDetailStackView(billType: BillType, feeDetail: FeeDetail) {
        let subStackView = UIStackView()
        subStackView.axis = .horizontal
        subStackView.alignment = .fill
        subStackView.distribution = .fill
        subStackView.spacing = 10
        subStackView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.image = billType.image

        let typeString = feeDetail.isGov == true ? "台" : ""

        let typeButton = UIButton()
        let priceLabel = UILabel()

        if let isGov = feeDetail.isGov {
            typeButton.setTitle("台\(billType.title)", for: .normal)
            typeButton.layer.cornerRadius = 5
            typeButton.tintColor = isGov == true ? .darkGray : .white
            typeButton.backgroundColor = .darkGray
            typeButton.isHidden = isGov == true ? false : true
            priceLabel.isHidden = true
        } else {
            priceLabel.text = "$ \(feeDetail.fee!) \(billType.unitString)"
        }

        let affordTypeButton = UIButton()
        let sperateString = feeDetail.affordType == "sperate" ? billType.sperateString : "總費用均分"
        affordTypeButton.setTitle("\(sperateString)", for: .normal)
        affordTypeButton.layer.cornerRadius = 3
        affordTypeButton.tintColor = .white
        affordTypeButton.backgroundColor = feeDetail.affordType == "sperate" ? .systemBrown : .magenta

        subStackView.addArrangedSubview(typeButton)
        subStackView.addArrangedSubview(priceLabel)
        subStackView.addArrangedSubview(affordTypeButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(subStackView)
    }
}
