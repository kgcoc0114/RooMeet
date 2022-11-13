//
//  RoomDetailHeaderView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class RoomDetailHeaderView: UICollectionReusableView {
    static let identifier = "RoomDetailHeaderView"

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.medium(size: 20)
            titleLabel.textColor = RMConstants.shared.title2FontColor
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
