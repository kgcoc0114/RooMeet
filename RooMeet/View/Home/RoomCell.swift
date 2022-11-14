//
//  RoomCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/14.
//

import UIKit

class RoomCell: UICollectionViewCell {
    static let identifier = "RoomCell"

    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var featuteTagButton: UIButton! {
        didSet {
            featuteTagButton.titleLabel!.font = UIFont.regular(size: 15)
            featuteTagButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
            featuteTagButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            featuteTagButton.isEnabled = false
            featuteTagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            featuteTagButton.setTitleColor(.hexColor(hex: "#FEF9EB"), for: .disabled)
            featuteTagButton.backgroundColor = .hexColor(hex: "#FAC748")
        }
    }

    @IBOutlet weak var leftTagButton: UIButton! {
        didSet {
            leftTagButton.titleLabel!.font = UIFont.regular(size: 15)
            leftTagButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
            leftTagButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            leftTagButton.isEnabled = false
            leftTagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            leftTagButton.setTitleColor(.hexColor(hex: "#93393F"), for: .disabled)
            leftTagButton.backgroundColor = .hexColor(hex: "#F9F0F1")
        }
    }
    @IBOutlet weak var regionLabel: UILabel! {
        didSet {
            regionLabel.textColor = .hexColor(hex: "#274156")
            regionLabel.font = UIFont.bold(size: 16)
        }
    }
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFill
            imageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    @IBOutlet weak var roomCardView: UIView! {
        didSet {
            roomCardView.layer.borderWidth = 0.1
            roomCardView.layer.borderColor = UIColor.lightGray.cgColor
            roomCardView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(data: Room) {
        if !data.roomImages.isEmpty {
            imageView.kf.setImage(
                with: data.roomImages[0],
                placeholder: UIImage(systemName: "house")?.withTintColor(.systemGray6))
        } else {
            imageView.image = UIImage(systemName: "house")?.withTintColor(.systemGray6)
        }

        if !data.county.isEmpty && !data.town.isEmpty {
            regionLabel.text = "\(data.county)\(data.town)"
        }

        if let price = data.roomMinPrice {
            priceLabel.text = "\(price)"
        }

        let count = data.rooms.count

        let leftTagTitle = "\(count) \(count == 1 ? "room" : "rooms") left"
        leftTagButton.setTitle(leftTagTitle, for: .normal)
    }
}
