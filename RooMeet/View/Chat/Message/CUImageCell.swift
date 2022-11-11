//
//  CUImageCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

class CUImageCell: UITableViewCell {
    static let reuseIdentifier = "\(CUImageCell.self)"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.layer.cornerRadius = RMConstants.shared.messageImageCornerRadius
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
