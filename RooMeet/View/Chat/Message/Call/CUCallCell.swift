//
//  CUCallCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class CUCallCell: MessageBaseCell {
    static let reuseIdentifier = "\(CUCallCell.self)"
    var msgType: MsgType = .currentUser

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

    var message: Message?
    var sendBy: ChatMember?
    var sendByMe = true

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        if let message = message {
            callTimeLabel.text = message.content
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }
}
