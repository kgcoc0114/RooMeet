//
//  CallCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/8.
//

import UIKit

class CallCell: UITableViewCell {
    static let reuseIdentifier = "\(CallCell.self)"

    @IBOutlet weak var otherUserView: UIStackView!
    @IBOutlet weak var currentUserView: UIStackView!
    @IBOutlet weak var otherUserCallTimeLabel: UILabel!
    @IBOutlet weak var currentUserCallTimeLabel: UILabel!

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleToFill
            avatarView.layer.cornerRadius = 50 / 2
        }
    }

    var message: Message?
    var sendBy: ChatMember?
    var sendByMe = true

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureLayout() {
        otherUserView.isHidden = sendByMe
        currentUserView.isHidden = !sendByMe

        if let message = message {
            if sendByMe {
                currentUserCallTimeLabel.text = message.content
            } else {
                otherUserCallTimeLabel.text = message.content
            }
        }

        if let sendBy = sendBy {
            if let profilePhoto = sendBy.profilePhoto {
                avatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
            } else {
                avatarView.image = UIImage.asset(.roomeet)
            }
        }
    }
}
