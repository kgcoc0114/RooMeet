//
//  RoomBasicCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomBasicCell: UICollectionViewCell {
    static let identifier = "RoomBasicCell"

    @IBOutlet weak var otherDescTextView: UITextView! {
        didSet {
            otherDescTextView.isEditable = false
            otherDescTextView.isScrollEnabled = false
            otherDescTextView.backgroundColor = .systemGray6
        }
    }

    @IBOutlet weak var regionLabel: UILabel! {
        didSet {
            regionLabel.font = UIFont.regularSubTitle()
        }
    }
    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.numberOfLines = 2
            titleLabel.font = UIFont.regularTitle()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(data: Room) {
        priceLabel.text = genPriceString(roomSpecs: data.rooms)
        regionLabel.text = "\(data.county)\(data.town)"
        titleLabel.text = data.title
        if let otherDesc = data.otherDescriction {
            otherDescTextView.text = otherDesc
        } else {
            otherDescTextView.isHidden = true
        }
    }

    func genPriceString(roomSpecs: [RoomSpec]) -> String {
        if !roomSpecs.isEmpty {
            let minPriceItem = roomSpecs.min { $0.price! < $1.price! }

            let maxPriceItem = roomSpecs.max { $0.price! > $1.price! }

            if let minPrice = minPriceItem,
                let maxPrice = maxPriceItem,
                let min = minPrice.price,
                let max = maxPrice.price {
                if min == max {
                    return "\(min) 元/月"
                } else {
                    return "\(min) - \(max) 元/月"
                }
            }
        }
        return "請私訊聊聊"
    }
}
