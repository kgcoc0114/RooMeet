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
    static let reuseIdentifier = "\(PostImageCell.self)"
    weak var delegate: PostImageCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }
}
