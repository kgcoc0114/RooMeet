//
//  ProfileItemCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/18.
//

import UIKit

class ProfileItemCell: UICollectionViewCell {
    static let identifier = "ProfileItemCell"

    var profileType: Profile?

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconBackgroundView: UIView!
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(count: Int?) {
        guard let profileType = profileType else {
            return
        }

        cellContentView.layer.cornerRadius = cellContentView.bounds.width * 0.1
        iconBackgroundView.layer.cornerRadius = iconBackgroundView.bounds.width * 0.2

        cellContentView.backgroundColor = profileType.color.background
        iconBackgroundView.backgroundColor = UIColor(named: "backgroundColor")

        iconImageView.image = profileType.iconImage.withTintColor(profileType.color.background)
        subTitleLabel.textColor = profileType.color.font
        countLabel.textColor = profileType.color.font
        subTitleLabel.font = UIFont.regular(size: 15)
        countLabel.font = UIFont.bold(size: 16)
        subTitleLabel.text = profileType.title

        if let postCount = count,
            "\(postCount)" != "0" {
            countLabel.text = "\(postCount)"
        } else {
            countLabel.isHidden = true
        }
    }
}
