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
        // Initialization code
    }
}

//extension OtherFeeHeaderCell: PostCell {
//    func configure(container: RMCellContainer) {
//        guard
//            let container = (container as? PostDataContainer),
//            let section = container.section else { return }
//        let tag = PostSection.allCases.firstIndex(of: section)
//        editAction.tag = tag ?? 0
//        titleLabel.text = PostVCString.otherFee.rawValue
//    }
//}
