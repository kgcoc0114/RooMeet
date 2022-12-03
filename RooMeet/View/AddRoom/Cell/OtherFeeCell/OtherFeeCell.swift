//
//  OtherFeeCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class OtherFeeCell: UICollectionViewCell {

    var completion: (() -> Void)?

    lazy private var editButton: UIButton = {
        let button = UIButton()
        button.setTitle("編輯", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(
            UIAction { _ in self.completion?() },
            for: .touchUpInside
        )
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.addSubview(editButton)

        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: self.topAnchor),
            editButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 200),
            editButton.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}
