//
//  OUCallCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class OUCallCell: MessageBaseCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        msgType = .other
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
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
            messageView.backgroundColor = msgType.backgroundColor
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var callTimeLabel: UILabel! {
        didSet {
            callTimeLabel.font = UIFont.regularText()
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleAspectFill
            avatarView.layer.cornerRadius = RMConstants.shared.avatarImageWidth / 2
        }
    }

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
                avatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
            } else {
                avatarView.image = UIImage.asset(.roomeet)
            }
        }
    }
}
