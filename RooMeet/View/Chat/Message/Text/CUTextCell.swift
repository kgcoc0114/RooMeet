//
//  CUTextCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

class CUTextCell: MessageBaseCell {
    static let reuseIdentifier = "\(CUTextCell.self)"

    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.translatesAutoresizingMaskIntoConstraints = false
            contentTextView.backgroundColor = msgType.backgroundColor
            contentTextView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            contentTextView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
            contentTextView.font = UIFont.regularText()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            contentTextView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: RMConstants.shared.CUTrailing),
            contentTextView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: RMConstants.shared.OULeading),
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
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }
}
