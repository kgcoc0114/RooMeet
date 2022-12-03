//
//  FurnitureDisplayCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import UIKit

class FurnitureDisplayCell: UITableViewCell {

    @IBOutlet weak var specLabel: UILabel! {
        didSet {
            specLabel.font = UIFont.regularSubTitle()
            specLabel.textColor = UIColor.mainDarkColor
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularTitle()
            titleLabel.textColor = UIColor.mainColor
        }
    }

    @IBOutlet weak var photoView: UIImageView! {
        didSet {
            photoView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            photoView.contentMode = .scaleAspectFill
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        specLabel.text = nil
        photoView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureCell(data: Furniture) {
        if let title = data.title {
            titleLabel.text = title
        } else {
            titleLabel.text = "家具"
        }

        var specs: [String] = []

        if let length = data.length {
            specs.append("長: \(length)cm")
        }

        if let width = data.width {
            specs.append("寬: \(width)cm")
        }

        if let height = data.height {
            specs.append("高: \(height)cm")
        }

        if let photoImageURL = data.imageURL {
            photoView.loadImage(photoImageURL, placeHolder: UIImage.asset(.furniture_placeholder))
        } else {
            photoView.image = UIImage.asset(.furniture_placeholder)
        }

        if specs.isEmpty {
            specLabel.text = "未填寫規格"
        } else {
            specLabel.text = specs.joined(separator: " ")
        }
    }
}
