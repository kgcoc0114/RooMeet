//
//  RoomCardCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomCardCell: UICollectionViewCell {
    static let identifier = "\(RoomCardCell.self)"

    var room: Room?

    @IBOutlet weak var cardView: CardView! {
        didSet {
            cardView.cornerRadius = 8
        }
    }

    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @IBOutlet weak var ownerLabel: UILabel! {
        didSet {
            ownerLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @IBOutlet weak var roomImageView: UIImageView! {
        didSet {
            roomImageView.translatesAutoresizingMaskIntoConstraints = false
            roomImageView.setCornerRadius(cornerRadius: 8)
            roomImageView.contentMode = .scaleAspectFill
            roomImageView.clipsToBounds = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(room: Room) {
        self.room = room
        if let room = self.room {
            if !room.roomImages.isEmpty {
                roomImageView.setImage(urlString: room.roomImages[0].absoluteString)
            }
            titleLabel.text = "\(room.county)\(room.town)"
            if let user = room.userData {
                ownerLabel.text = "\(user.name)"
            }


            if !room.rooms.isEmpty {
                let minPriceItem = room.rooms.min { $0.price! > $1.price! }
                if let minPrice = minPriceItem,
                   let price = minPrice.price {
                    priceLabel.text = "\(price) 元/月"
                } else {
                    priceLabel.text = "點進去看更多"
                }
            }
        }
    }
}
