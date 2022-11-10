//
//  DateCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import UIKit

class DateCell: UICollectionViewCell {
    static let identifier = "DateCell"

    var date = Calendar.current.dateComponents(in: TimeZone.current, from: Date())

    @IBOutlet weak var weekdayLabel: UILabel! {
        didSet {
            weekdayLabel.font = UIFont.systemFont(ofSize: 20, weight: .light)
        }
    }

    @IBOutlet weak var dayLabel: UILabel! {
        didSet {
            dayLabel.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(date: DateComponents) {
        dayLabel.text = String(describing: date.day)
        weekdayLabel.text = String(describing: date.weekday)
    }
}
