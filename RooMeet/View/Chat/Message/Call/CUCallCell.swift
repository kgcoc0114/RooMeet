//
//  CUCallCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

class CUCallCell: MessageBaseCell {
    static let reuseIdentifier = "\(CUCallCell.self)"

    @IBOutlet weak var messageView: UIView! {
        didSet {
            messageView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            messageView.backgroundColor = .hexColor(hex: RMColor.palePink.hex)        }
    }

    @IBOutlet weak var callTimeLabel: UILabel! {
        didSet {
            callTimeLabel.font = UIFont.regular(size: RMConstants.shared.reservationStatusFontSize)
        }
    }

    var message: Message?
    var sendBy: ChatMember?
    var sendByMe = true


    override func awakeFromNib() {
        super.awakeFromNib()
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func configureLayout() {
        if let message = message {
            callTimeLabel.text = message.content
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }
}
