//
//  BlockCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/23.
//

import UIKit
protocol BlockCellDelegate: AnyObject {
    func didSelectedUnblock(_ cell: BlockCell, isUnBlock: Bool)
}

class BlockCell: UICollectionViewCell {
    static let reuseIdentifier = "BlockCell"

    @IBOutlet weak var unblockbutton: UIButton! {
        didSet {
            unblockbutton.setTitle("", for: .normal)
            unblockbutton.backgroundColor = .clear

            unblockbutton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
            unblockbutton.setImage(UIImage(systemName: "circle"), for: .normal)
            unblockbutton.isSelected = false
            unblockbutton.addTarget(self, action: #selector(unblockCheck), for: .touchUpInside)
        }
    }

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.textColor = .mainDarkColor
            nameLabel.font = .regularSubTitle()
        }
    }

    @IBOutlet weak var imageView: UIImageView!

    weak var delegate: BlockCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        imageView.layer.cornerRadius = imageView.bounds.width / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        unblockbutton.isSelected = false
    }

    func configureCell(data: User) {
        nameLabel.text = data.name
        if data.profilePhoto == nil {
            imageView.image = UIImage.asset(.profile_user)
        } else {
            imageView.loadImage(data.profilePhoto, placeHolder: UIImage.asset(.profile_user))
        }
    }

    @objc private func unblockCheck(_ sender: UIButton) {
        sender.isSelected.toggle()
        delegate?.didSelectedUnblock(self, isUnBlock: sender.isSelected)
    }
}
