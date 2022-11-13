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
            return UIColor.hexColor(hex: RMColor.palePink.hex)
        case .other:
            return UIColor.white
        }
    }
}

class OUTextCell: MessageBaseCell {
    static let reuseIdentifier = "\(OUTextCell.self)"

    var msgType: MsgType = .other
    var message: Message?
    var sendBy: ChatMember?

    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.translatesAutoresizingMaskIntoConstraints = false
            contentTextView.backgroundColor = msgType.backgroundColor
            contentTextView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
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
        self.backgroundColor = UIColor.hexColor(hex: RMColor.snow.hex)

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentTextView.trailingAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: contentTextView.trailingAnchor, constant: 5),
            timeLabel.bottomAnchor.constraint(equalTo: contentTextView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }


    override func configureLayout() {
        if let message = message,
            let sendBy = sendBy {
            avatarView.setImage(urlString: sendBy.profilePhoto)
            contentTextView.text = message.content
            let messageDate = message.createdTime.dateValue()

            dateLabel.text = RMDateFormatter.shared.datetimeWithLocaleString(date: messageDate, dateFormat: "MM/dd")
            timeLabel.text = RMDateFormatter.shared.datetimeWithLocaleString(date: messageDate, dateFormat: "HH:mm")

            if isSameDate(date: messageDate) {
                dateLabel.isHidden = true
            }
        }
    }
}
