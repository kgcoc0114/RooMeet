//
//  RoomDisplayCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit

protocol RoomDisplayCellDelegate: AnyObject {
    func didClickedLike(_ cell: RoomDisplayCell, like: Bool)
}

class RoomDisplayCell: UICollectionViewCell {
    static let identifier = "RoomDisplayCell"

    @IBOutlet weak var rsvnInfoView: UIView!
    @IBOutlet weak var favoriteInfoView: UIView!
    @IBOutlet weak var likeButton: UIButton! {
        didSet {
            likeButton.translatesAutoresizingMaskIntoConstraints = false
            likeButton.backgroundColor = .clear
            likeButton.setTitle("", for: .normal)
            likeButton.setImage(UIImage.asset(.heart), for: .normal)
            likeButton.tintColor = UIColor.subTitleRedColor
        }
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var displayBackgroundView: UIView!
    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.textColor = .subTitleRedColor
        }
    }

    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var roomSpecLabel: UILabel!

    var isLike = false {
        didSet {
            if isLike == true {
                likeButton.setImage(UIImage.asset(.heart_fill), for: .normal)
            } else {
                likeButton.setImage(UIImage.asset(.heart), for: .normal)
            }
        }
    }

    weak var delegate: RoomDisplayCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.regularSubTitle()
        titleLabel.textColor = UIColor.mainColor
        displayBackgroundView.layer.cornerRadius = 10
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        regionLabel.font = UIFont.regularText()
        priceLabel.font = UIFont.regularText()
        roomSpecLabel.font = UIFont.regularText()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isLike = false
    }

    func configureCell(data: Room) {
        if !data.roomImages.isEmpty {
            imageView.kf.setImage(
                with: data.roomImages.first,
                placeholder: UIImage.asset(.room_placeholder)
            )
        } else {
            imageView.image = UIImage.asset(.room_placeholder)
        }

        titleLabel.text = data.title

        if !data.county.isEmpty && !data.town.isEmpty {
            regionLabel.text = "\(data.county)\(data.town)"
        }

        regionLabel.text = "\(data.county)\(data.town)"

        if
            let price = data.roomMinPrice,
            price != -1 {
            priceLabel.text = "\(price) ???/???"
        } else {
            priceLabel.text = "????????????"
        }

        if !data.rooms.isEmpty {
            data.rooms.forEach { room in
                if room.price == nil {
                    roomSpecLabel.text = "????????????"
                }

                if room.price == data.roomMinPrice {
                    guard
                        let roomType = room.roomType,
                        let space = room.space else { return }
                    roomSpecLabel.text = "\(roomType) \(space) ???"
                }
            }
        }
    }

    @IBAction func likeAction(_ sender: Any) {
        isLike.toggle()
        delegate?.didClickedLike(self, like: isLike)
    }
}
