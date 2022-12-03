//
//  RoomDetailHeaderView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class RoomDetailHeaderView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularTitle()
            titleLabel.textColor = UIColor.mainDarkColor
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
