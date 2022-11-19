//
//  ReservationDisplayCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/13.
//

import UIKit

class ReservationDisplayCell: UICollectionViewCell {
    static let identifier = "ReservationDisplayCell"

    @IBOutlet weak var statusButton: UIButton! {
        didSet {
            statusButton.isEnabled = false
            statusButton.titleLabel!.font = UIFont.regularText()
            statusButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            statusButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            statusButton.setTitleColor(.white, for: .disabled)
        }
    }

    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.font = UIFont.regularText()
            priceLabel.textColor = .hexColor(hex: "#BA4F56")
        }
    }

    @IBOutlet weak var roomTitleLabel: UILabel! {
        didSet {
            roomTitleLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var periodLabel: UILabel! {
        didSet {
            periodLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.font = UIFont.regularTitle()
        }
    }

    @IBOutlet weak var regionLabel: UILabel! {
        didSet {
            regionLabel.font = UIFont.regularText()
        }
    }

    @IBOutlet weak var cardView: CardView! {
        didSet {
            cardView.shadowColor = .hexColor(hex: "#363130")
            cardView.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    @IBOutlet weak var roomImageView: UIImageView! {
        didSet {
            roomImageView.translatesAutoresizingMaskIntoConstraints = false
            roomImageView.contentMode = .scaleAspectFill
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        roomImageView.layer.cornerRadius = roomImageView.bounds.width * 0.15
    }

    func configureCell(data: Reservation) {
        guard let requestTime = data.requestTime else {
            return
        }

        dateLabel.text = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
        periodLabel.text = data.period

        guard let roomDetail = data.roomDetail else {
            return
        }
        roomTitleLabel.text = roomDetail.title

        regionLabel.text = "\(roomDetail.county)\(roomDetail.town)"

        if let roomMinPrice = roomDetail.roomMinPrice {
            priceLabel.text = "$\(String(describing: Int(roomMinPrice))) 月"
        }


        if !roomDetail.roomImages.isEmpty {
            roomImageView.setImage(urlString: roomDetail.roomImages[0].absoluteString)
        }

        if let rawAcceptStatus = data.acceptedStatus {
            let acceptStatus = AcceptedStatus(rawValue: rawAcceptStatus)
            statusButton.setTitle(data.acceptedStatus, for: .normal)
            statusButton.backgroundColor = acceptStatus?.tagColor
        }
    }
}
