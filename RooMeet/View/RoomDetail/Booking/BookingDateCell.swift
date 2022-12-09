//
//  BookingDateCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit
import SwiftUI

enum BookingPeriod: CaseIterable {
    case morning
    case afternoon
    case night

    var descrption: String {
        switch self {
        case .morning:
            return "早上 (08:00 - 12:00)"
        case .afternoon:
            return "下午 (12:00 - 18:00)"
        case .night:
            return "晚上 (18:00 - 20:00)"
        }
    }

    var subDesc: String {
        switch self {
        case .morning:
            return "早上 (08 - 12 時)"
        case .afternoon:
            return "下午 (12 - 18 時)"
        case .night:
            return "晚上 (18 - 20 時)"
        }
    }

    var hour: Int {
        switch self {
        case .morning:
            return 8
        case .afternoon:
            return 12
        case .night:
            return 18
        }
    }
}

enum RMWeekday: Int, CaseIterable {
    case sun
    case mon
    case tue
    case wed
    case thu
    case fri
    case sat

    var descrption: String {
        switch self {
        case .sun:
            return "SUN"
        case .mon:
            return "MON"
        case .tue:
            return "TUE"
        case .wed:
            return "WED"
        case .thu:
            return "THU"
        case .fri:
            return "FRI"
        case .sat:
            return "SAT"
        }
    }

    var descZhTw: String {
        switch self {
        case .sun:
            return "星期天"
        case .mon:
            return "星期一"
        case .tue:
            return "星期二"
        case .wed:
            return "星期三"
        case .thu:
            return "星期四"
        case .fri:
            return "星期五"
        case .sat:
            return "星期六"
        }
    }
}

protocol BookingDateCellDelegate: AnyObject {
    func didSelectedDate(_ cell: BookingDateCell, date: DateComponents)
}

class BookingDateCell: UICollectionViewCell {
    private let selectedColor = UIColor.mainDarkColor
    private let unselectedColor = UIColor.mainColor


    weak var delegate: BookingDateCellDelegate?

    var date: DateComponents?


    @IBOutlet weak var weekdayLabel: UILabel! {
        didSet {
            weekdayLabel.font = UIFont.regularSmallText()
            weekdayLabel.textColor = unselectedColor
        }
    }

    @IBOutlet weak var dateView: DateView! {
        didSet {
            dateView.layer.borderWidth = 1
            dateView.layer.borderColor = unselectedColor.cgColor
            dateView.layer.cornerRadius = RMConstants.shared.dataPickerCornerRadius
            dateView.backgroundColor = .clear
            // action
            dateView.isUserInteractionEnabled = true
            let clickEvent = UITapGestureRecognizer(target: self, action: #selector(selectDate))
            dateView.addGestureRecognizer(clickEvent)
        }
    }

    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.textColor = unselectedColor
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                dateView.layer.borderColor = selectedColor.cgColor
                weekdayLabel.textColor = selectedColor
                dateLabel.textColor = selectedColor
            } else {
                dateView.layer.borderColor = unselectedColor.cgColor
                weekdayLabel.textColor = unselectedColor
                dateLabel.textColor = unselectedColor
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(date: DateComponents) {
        self.date = date
        if
            let weekday = date.weekday,
            let day = date.day {
            let weekdayString = RMWeekday.allCases[weekday - 1].descrption
            weekdayLabel.text = weekdayString
            dateLabel.text = "\(day)"
        }
    }

    @objc func selectDate(_ sender: UITapGestureRecognizer) {
        guard let selected = self.date else { return }
        delegate?.didSelectedDate(self, date: selected)
    }
}

extension BookingDateCell: RoomDetailCell {
    func configure(container: RoomDetailContainer) {
        guard let bookingDate = (container as? BookingContainer)?.bookingDate else {
            return
        }

        if
            let weekday = bookingDate.weekday,
            let day = bookingDate.day {
            let weekdayString = RMWeekday.allCases[weekday - 1].descrption
            weekdayLabel.text = weekdayString
            dateLabel.text = "\(day)"
        }
    }
}

class DateView: UIView {
    var date: DateComponents?
}
