//
//  MessageBaseCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

class MessageBaseCell: UITableViewCell {
    var msgType: MsgType = .currentUser
    var message: Message?
    var sendBy: ChatMember?

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.regular(size: RMConstants.shared.dateTimeFontSize)
        label.tintColor = UIColor.mainDarkColor
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.regular(size: RMConstants.shared.dateTimeFontSize)
        label.tintColor = UIColor.mainDarkColor
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.mainBackgroundColor
        addSubview(dateLabel)
        addSubview(timeLabel)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func isSameDate(date: Date) -> Bool {
        return RMDateFormatter.shared.datetimeWithLocaleString(date: date, dateFormat: "YY/MM/dd") == RMDateFormatter.shared.datetimeWithLocaleString(date: Date(),dateFormat: "YY/MM/dd")
    }

    func assignDatetime(messageDate: Date) {
        dateLabel.text = RMDateFormatter.shared.datetimeWithLocaleString(date: messageDate, dateFormat: "MM/dd")
        timeLabel.text = RMDateFormatter.shared.datetimeWithLocaleString(date: messageDate, dateFormat: "HH:mm")

        if isSameDate(date: messageDate) {
            dateLabel.isHidden = true
        }
    }

    func configureLayout() {
    }
}
