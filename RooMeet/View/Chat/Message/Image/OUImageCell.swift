//
//  OUImageCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

protocol OUImageCellDelegate: AnyObject {
    func didClickImageView(_ cell: OUImageCell, imageURL: String)
}

class OUImageCell: MessageBaseCell {
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

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.layer.cornerRadius = RMConstants.shared.avatarImageWidth / 2
            avatarView.contentMode = .scaleAspectFill
        }
    }

    weak var delegate: OUImageCellDelegate?

    var imageURL: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        msgType = .other
        selectionStyle = .none
        self.backgroundColor = UIColor.mainBackgroundColor
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 5),
            timeLabel.bottomAnchor.constraint(equalTo: photoView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        photoView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        if
            let message = message,
            let sendBy = sendBy {
            if let profilePhoto = sendBy.profilePhoto {
                avatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
            } else {
                avatarView.image = UIImage.asset(.roomeet)
            }
            imageURL = message.content
            photoView.loadImage(message.content, placeHolder: UIImage.asset(.room_placeholder))
            assignDatetime(messageDate: message.createdTime.dateValue())
        }
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let imageURL = imageURL else { return }
        delegate?.didClickImageView(self, imageURL: imageURL)
    }
}
