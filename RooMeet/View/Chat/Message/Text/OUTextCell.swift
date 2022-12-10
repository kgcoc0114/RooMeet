//
//  OUTextCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

enum MsgType {
    case currentUser
    case other

    var backgroundColor: UIColor {
        switch self {
        case .currentUser:
            return UIColor.msgBackgroundColor
        case .other:
            return UIColor.white
        }
    }
}

class OUTextCell: MessageBaseCell {
    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.translatesAutoresizingMaskIntoConstraints = false
            contentTextView.backgroundColor = msgType.backgroundColor
            contentTextView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            contentTextView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
            contentTextView.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.layer.cornerRadius = RMConstants.shared.avatarImageWidth / 2
            avatarView.contentMode = .scaleAspectFill
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        msgType = .other
        self.backgroundColor = UIColor.mainBackgroundColor

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentTextView.trailingAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: contentTextView.trailingAnchor, constant: 5),
            timeLabel.bottomAnchor.constraint(equalTo: contentTextView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension OUTextCell: ChatCell {
    func configure(for data: ChatData) {
        let message = data.message

        if let sendBy = data.otherUser {
            if let profilePhoto = sendBy.profilePhoto {
                avatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
            } else {
                avatarView.image = UIImage.asset(.roomeet)
            }

            contentTextView.text = message.content
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }
}
