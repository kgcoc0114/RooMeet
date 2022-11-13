//
//  TagCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

class TagCell: UICollectionViewCell {
    static let identifier = "TagCell"

    @IBOutlet weak var tagButton: UIButton! {
        didSet {
            tagButton.isEnabled = false
            tagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            tagButton.titleLabel!.font = UIFont.regular(size: 12)
            tagButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func styleCell(backgroundColor: UIColor, tintColor: UIColor) {
        tagButton.setTitleColor(tintColor, for: .disabled)
        tagButton.backgroundColor = backgroundColor
    }

    func configureCell(data: String) {
        tagButton.setTitle(data, for: .normal)
    }
}
