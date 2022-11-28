//
//  RoomImagesCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomImagesCell: UICollectionViewCell {
    static let identifier = "RoomImagesCell"

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.isPagingEnabled = true
        }
    }

    @IBOutlet weak var pageControl: UIPageControl! {
        didSet {
            pageControl.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.delegate = self
    }

    override func prepareForReuse() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
        }
    }
}

// MARK: - Delegate
extension RoomImagesCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int((scrollView.contentOffset.x / scrollView.frame.width).rounded())
        pageControl.currentPage = page
        let offset = CGPoint(x: CGFloat(page) * scrollView.frame.width, y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}

// MARK: - Configure Layout
extension RoomImagesCell {
    func configureCell(images: [URL]) {
        images.forEach { imageURL in
            let imageView = UIImageView()
            imageView.loadImage(imageURL.absoluteString, placeHolder: UIImage.asset(.room_placeholder))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            stackView.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4 / 3 )
            ])
        }
        if stackView.arrangedSubviews.isEmpty {
            let imageView = UIImageView()
            imageView.image = UIImage.asset(.room_placeholder)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            stackView.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4 / 3 )
            ])
        }
        pageControl.numberOfPages = images.isEmpty ? 1 : images.count
    }
}
