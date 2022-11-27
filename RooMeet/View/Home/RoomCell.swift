//
//  RoomCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/14.
//

import UIKit

class RoomCell: UICollectionViewCell {
    static let identifier = "RoomCell"

    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.textColor = UIColor.subTitleRedColor
            priceLabel.font = UIFont.regularText()
        }
    }

    @IBOutlet weak var featuteTagButton: UIButton! {
        didSet {
            featuteTagButton.titleLabel!.font = UIFont.regularText()
            featuteTagButton.contentEdgeInsets = UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
            featuteTagButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            featuteTagButton.isEnabled = false
            featuteTagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            featuteTagButton.setTitleColor(.white, for: .disabled)
            featuteTagButton.backgroundColor = .subTitleOrangeColor
        }
    }

    @IBOutlet weak var leftTagButton: UIButton! {
        didSet {
            leftTagButton.titleLabel!.font = UIFont.regularText()
            leftTagButton.contentEdgeInsets = UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
            leftTagButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            leftTagButton.isEnabled = false
            leftTagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            leftTagButton.setTitleColor(.subTitleRedBGColor, for: .disabled)
            leftTagButton.backgroundColor = .subTitleRedColor
        }
    }

    @IBOutlet weak var regionLabel: UILabel! {
        didSet {
            regionLabel.textColor = UIColor.mainColor
            regionLabel.font = UIFont.boldText()
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor.mainDarkColor
            titleLabel.font = UIFont.boldTitle()
            titleLabel.numberOfLines = 1
        }
    }

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFill
            imageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var roomCardView: UIView! {
        didSet {
            roomCardView.layer.borderWidth = 0.5
            roomCardView.layer.borderColor = UIColor.mainLightColor.cgColor
            roomCardView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(data: Room) {
        if !data.roomImages.isEmpty {
            imageView.kf.setImage(
                with: data.roomImages[0],
                placeholder: UIImage.asset(.room_placeholder))
        } else {
            imageView.image = UIImage.asset(.room_placeholder)
        }

        if !data.title.isEmpty {
            titleLabel.text = "\(data.title)"
        }

        if !data.county.isEmpty && !data.town.isEmpty {
            regionLabel.text = "\(data.county)\(data.town)"
        }

        if let price = data.roomMinPrice,
            price != -1 {
            priceLabel.text = "\(price) 元/月"
        } else {
            priceLabel.text = "查看更多"
        }

        if !data.roomHighLights.isEmpty {
            featuteTagButton.setTitle(data.roomHighLights.first, for: .disabled)
        } else {
            featuteTagButton.isHidden = true
        }

        let count = data.rooms.count

        let leftTagTitle = "\(count) \(count == 1 ? "room" : "rooms") left"
        leftTagButton.setTitle(leftTagTitle, for: .normal)
    }
}
