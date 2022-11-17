//
//  RoomDisplayCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit

class RoomDisplayCell: UICollectionViewCell {
    static let identifier = "RoomDisplayCell"
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var displayBackgroundView: CardView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        displayBackgroundView.cornerRadius = 10
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        tagView.layer.cornerRadius = 15
        tagView.backgroundColor = .orange
        tagLabel.tintColor = .white
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
            titleLabel.text = "\(data.county)\(data.town)找室友"
        }

        if let owner = data.userData {
            let gender = Gender.allCases[owner.gender ?? 0].rawValue
            ownerLabel.text = "\(owner.name!) / \(owner.age) / \(gender)"
        }

        if let price = data.roomMinPrice {
            priceLabel.text = "$ \(price) / Month"
        }

        tagLabel.text = "缺 \(data.rooms.count)"
    }
}
