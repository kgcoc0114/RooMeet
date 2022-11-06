//
//  RegionPickerCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class RegionPickerCell: UITableViewCell {
    static let reuseIdentifier = "\(RegionPickerCell.self)"
    @IBOutlet weak var regionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
