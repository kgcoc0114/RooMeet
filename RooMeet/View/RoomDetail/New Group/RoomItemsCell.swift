//
//  RoomItemsCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomItemsCell: UICollectionViewCell {
    static let identifier = "RoomItemsCell"

    var itemType: String?

    @IBOutlet weak var itemBackgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        itemBackgroundView.layer.cornerRadius = 10
        titleLabel.tintColor = .white
    }

    func configureCell(data: String, itemType: String = "rules") {
        titleLabel.text = data
        itemBackgroundView.backgroundColor = itemType == "rules" ? .green : .orange
    }
}
