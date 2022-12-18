//
//  PostImageCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

protocol PostImageCellDelegate: AnyObject {
    func didClickImageView(_ cell: PostImageCell)
}

class PostImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    weak var delegate: PostImageCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(imageTapped(tapGestureRecognizer:))
        )
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.contentMode = .scaleAspectFill
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }
}

extension PostImageCell: PostCell {
    func configure(container: RMCellContainer) {
        guard
            let container = (container as? PostDataContainer)
        else { return }

        let index = container.indexPath.item
        if container.roomImages?[index] != UIImage.asset(.add) {
            imageView.image = container.roomImages?[index] ?? UIImage.asset(.add)
        } else {
            imageView.loadImage(
                index >= container.roomImagesURL?.count ?? 3
                ? nil
                : container.roomImagesURL?[index].absoluteString,
                placeHolder: UIImage.asset(.add)
            )
        }
    }
}
