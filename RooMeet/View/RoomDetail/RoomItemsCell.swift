//
//  RoomItemsCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomItemsCell: UICollectionViewCell {
    static let reuseIdentifier = "\(RoomItemsCell.self)"

    var item: String?

    @IBOutlet weak var itemBackgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        itemBackgroundView.layer.cornerRadius = 10
        titleLabel.tintColor = .white
    }

    func configureCell(item: String, type: String = "rules") {
        titleLabel.text = item
        itemBackgroundView.backgroundColor = type == "rules" ? .green : .orange
    }

}
