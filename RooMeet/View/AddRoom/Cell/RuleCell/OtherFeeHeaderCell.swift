//
//  OtherFeeHeaderCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class OtherFeeHeaderCell: UICollectionViewCell {
    @IBOutlet weak var editAction: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension OtherFeeHeaderCell: PostCell {
    func configure(container: RMCellContainer) {
        guard
            let container = (container as? PostDataContainer),
            let tag = PostSection.allCases.firstIndex(of: .feeHeader)
        else { return }
        editAction.tag = tag
        titleLabel.text = PostVCString.otherFee.rawValue
    }
}
