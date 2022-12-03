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
    var isPicked = false {
        didSet {
            self.backgroundColor = isPicked == true ? UIColor.mainColor : UIColor.mainLightColor
            regionLabel.textColor = isPicked == true ? UIColor.white : UIColor.mainDarkColor
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isPicked = false
        regionLabel.textColor = nil
        self.backgroundColor = nil
    }
}
