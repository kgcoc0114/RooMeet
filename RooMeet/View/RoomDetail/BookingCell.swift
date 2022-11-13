//
//  BookingCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import UIKit
protocol BookingCellDelegate: AnyObject {
    func didSendRequest(date: DateComponents, selectPeriod: BookingPeriod)
}

class BookingCell: UICollectionViewCell {
    static let identifier = "BookingCell"

    var delegate: BookingCellDelegate?

    @IBOutlet weak var bookingView: BookingView!
    override func awakeFromNib() {
        super.awakeFromNib()
        bookingView.delegate = self
    }

}

extension BookingCell: BookingViewDelegate {
    func didSendRequest(date: DateComponents, selectPeriod: BookingPeriod) {
        print("BookingCell", #function)
        delegate?.didSendRequest(date: date, selectPeriod: selectPeriod)
    }
}

