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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell() {

    }
}
