//
//  RoomBasicCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

protocol RoomBasicCellDelegate: AnyObject {
    func didClickedLike(_ cell: RoomBasicCell, like: Bool)
}

class RoomBasicCell: UICollectionViewCell {
    static let identifier = "RoomBasicCell"
    weak var delegate: RoomBasicCellDelegate?

    var isLike = false {
        didSet {
            if isLike == true {
                likeButton.setImage(UIImage.asset(.heart_fill), for: .normal)
            } else {
                likeButton.setImage(UIImage.asset(.heart), for: .normal)
            }
        }
    }

    @IBOutlet weak var otherDescTextView: UITextView! {
        didSet {
            otherDescTextView.isEditable = false
            otherDescTextView.isScrollEnabled = false
            otherDescTextView.backgroundColor = .systemGray6
        }
    }

    @IBOutlet weak var likeButton: UIButton! {
        didSet {
            likeButton.backgroundColor = .clear
            likeButton.setTitle("", for: .normal)
            likeButton.setImage(UIImage.asset(.heart), for: .normal)
            likeButton.tintColor = .subTitleRedColor
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
        priceLabel.text = genPriceString(data: data)
        regionLabel.text = "\(data.county)\(data.town)"
        titleLabel.text = data.title
        if let otherDesc = data.otherDescriction {
            otherDescTextView.text = otherDesc
        } else {
            otherDescTextView.isHidden = true
        }
    }

    func genPriceString(data: Room) -> String {
        if
            let price = data.roomMinPrice,
            price != -1 {
            let roomSpecs = data.rooms
            let minPriceItem = roomSpecs.min { $0.price! < $1.price! }

            let maxPriceItem = roomSpecs.max { $0.price! > $1.price! }

            if
                let minPrice = minPriceItem,
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

    @IBAction func likeAction(_ sender: Any) {
        delegate?.didClickedLike(self, like: !isLike)
    }
}
