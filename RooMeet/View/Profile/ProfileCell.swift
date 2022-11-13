//
//  ProfileCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

class ProfileCell: UITableViewCell {
    static let identifier = "ProfileCell"

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    var profileType: Profile?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureCell() {
        guard let profileType = profileType else {
            return
        }

        iconImageView.image = profileType.iconImage
        titleLabel.text = profileType.title
    }
}
