//
//  RoomImagesCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

protocol RoomImagesCellDelegate: AnyObject {
    func didClickedLike(like: Bool)
}

class RoomImagesCell: UICollectionViewCell {
    static let identifier = "RoomImagesCell"

    weak var delegate: RoomImagesCellDelegate?

    @IBOutlet weak var likeButton: UIButton! {
        didSet {
            likeButton.backgroundColor = .clear
            likeButton.setTitle("", for: .normal)
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            likeButton.tintColor = .white
        }
    }

    var isLike: Bool = false {
        didSet {
            if isLike == true {
                likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            } else {
                likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            }
        }
    }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.isPagingEnabled = true
        }
    }
    @IBOutlet weak var pageControl: UIPageControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.delegate = self
    }
    @IBAction func likeAction(_ sender: Any) {
        isLike.toggle()
        delegate?.didClickedLike(like: isLike)
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
            imageView.setImage(urlString: imageURL.absoluteString)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            stackView.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4/3 )
            ])
        }
        pageControl.numberOfPages = images.count
    }
}
