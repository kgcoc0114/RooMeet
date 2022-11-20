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
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(count: Int?) {
        guard let profileType = profileType else {
            return
        }

        cellContentView.layer.cornerRadius = cellContentView.bounds.width * 0.1

        cellContentView.backgroundColor = profileType.color.background

        iconImageView.image = profileType.iconImage.withTintColor(profileType.color.font)
        subTitleLabel.textColor = profileType.color.font
        subTitleLabel.font = UIFont.regular(size: 15)
        subTitleLabel.text = profileType.title
    }
}
