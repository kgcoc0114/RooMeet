//
//  SettingCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/25.
//

import UIKit

class SettingCell: UITableViewCell {
    static let identifier = "SettingCell"

    @IBOutlet weak var iconImageView: UIImageView! {
        didSet {
            iconImageView.tintColor = .white
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = .regularTitle()
            titleLabel.textColor = .mainDarkColor
        }
    }

    @IBOutlet weak var bgView: UIView! {
        didSet {
            bgView.layer.borderWidth = 0.8
            bgView.layer.borderColor = UIColor.mainLightColor.cgColor
            bgView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureCell(data: SettingItem) {
        titleLabel.text = data.title
        iconImageView.image = data.icon
        iconImageView.tintColor = data.backgroundColor
    }
}
