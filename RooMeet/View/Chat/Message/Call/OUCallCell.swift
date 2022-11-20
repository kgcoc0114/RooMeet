//
//  OUCallCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class OUCallCell: MessageBaseCell {
    static let reuseIdentifier = "\(OUCallCell.self)"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: 5),
            timeLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    @IBOutlet weak var messageView: UIView! {
        didSet {
            messageView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            messageView.backgroundColor = .white
        }
    }

    @IBOutlet weak var callTimeLabel: UILabel! {
        didSet {
            callTimeLabel.font = UIFont.regular(size: RMConstants.shared.reservationStatusFontSize)
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleAspectFill
            avatarView.layer.cornerRadius = RMConstants.shared.avatarImageWidth / 2
        }
    }

    var message: Message?
    var sendBy: ChatMember?
    var sendByMe = true

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        if let message = message {
            callTimeLabel.text = message.content
            assignDatetime(messageDate: message.createdTime.dateValue())
        }

        if let sendBy = sendBy {
            if let profilePhoto = sendBy.profilePhoto {
                avatarView.setImage(urlString: profilePhoto)
            } else {
                avatarView.image = UIImage.asset(.profile_user)
            }
        }


    }
}
