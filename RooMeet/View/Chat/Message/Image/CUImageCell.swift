//
//  CUImageCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

protocol CUImageCellDelegate: AnyObject {
    func didClickImageView(_ cell: CUImageCell, imageURL: String)
}

class CUImageCell: MessageBaseCell {
    @IBOutlet weak var photoView: UIImageView! {
        didSet {
            photoView.contentMode = .scaleAspectFill
            photoView.translatesAutoresizingMaskIntoConstraints = false
            photoView.layer.cornerRadius = RMConstants.shared.messageCornerRadius

            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped(tapGestureRecognizer:)))
            photoView.isUserInteractionEnabled = true
            photoView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    weak var delegate: CUImageCellDelegate?

    var imageURL: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.backgroundColor = UIColor.mainBackgroundColor
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: photoView.leadingAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalTo: photoView.leadingAnchor, constant: -5),
            timeLabel.bottomAnchor.constraint(equalTo: photoView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        if let message = message,
           let _ = sendBy {
            imageURL = message.content

            photoView.loadImage(imageURL, placeHolder: UIImage.asset(.room_placeholder))
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let imageURL = imageURL else { return }
        delegate?.didClickImageView(self, imageURL: imageURL)
    }
}
