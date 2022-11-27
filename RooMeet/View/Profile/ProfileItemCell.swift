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
    @IBOutlet weak var subTitleLabel: UILabel! {
        didSet {
            subTitleLabel.font = .regularSubTitle()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell() {
        guard let profileType = profileType else {
            return
        }

        cellContentView.layer.cornerRadius = cellContentView.bounds.width * 0.1

        cellContentView.backgroundColor = profileType.color.background

        iconImageView.tintColor = profileType.color.font
        iconImageView.image = profileType.iconImage
        subTitleLabel.textColor = profileType.color.font
        subTitleLabel.text = profileType.title
    }
}
