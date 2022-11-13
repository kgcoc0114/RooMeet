//
//  CUTextCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

class CUTextCell: MessageBaseCell {
    static let reuseIdentifier = "\(CUTextCell.self)"

    var msgType: MsgType = .currentUser
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

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.hexColor(hex: RMColor.snow.hex)
        selectionStyle = .none
        addSubview(dateLabel)
        addSubview(timeLabel)
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            contentTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: RMConstants.shared.CUTrailing),
            contentTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: RMConstants.shared.OULeading),
            contentTextView.heightAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.5),
            dateLabel.trailingAnchor.constraint(equalTo: contentTextView.leadingAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalTo: contentTextView.leadingAnchor, constant: -5),
            timeLabel.bottomAnchor.constraint(equalTo: contentTextView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        if let message = message {
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