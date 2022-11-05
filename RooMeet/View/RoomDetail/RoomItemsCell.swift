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

    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(item: String) {
        titleLabel.text = item
    }

}
