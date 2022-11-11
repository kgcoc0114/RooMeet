//
//  MessageBaseCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

class MessageBaseCell: UITableViewCell {

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.regular(size: RMConstants.shared.dateTimeFontSize)
        label.tintColor = UIColor.B1
        return label
    }()

    

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.regular(size: RMConstants.shared.dateTimeFontSize)
        label.tintColor = UIColor.B1
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(dateLabel)
        addSubview(timeLabel)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func isSameDate(date: Date) -> Bool {
        return RMDateFormatter.shared.datetimeWithLocaleString(date: date, dateFormat: "YY/MM/dd") == RMDateFormatter.shared.datetimeWithLocaleString(date: Date(), dateFormat: "YY/MM/dd")
    }
}


