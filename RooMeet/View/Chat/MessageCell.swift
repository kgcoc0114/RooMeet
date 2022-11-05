//
//  MessageCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

//enum MsgType {
//    case currentUser
//    case other
//}

class MessageCell: UITableViewCell {
    static let reuseIdentifier = "\(MessageCell.self)"
    
    var msgType: MsgType = .currentUser
    var message: Message?
    var sendBy: ChatMember?


    @IBOutlet weak var contentLabel: UILabel! {
        didSet {
            contentLabel.translatesAutoresizingMaskIntoConstraints = false
            contentLabel.textAlignment = .left
            contentLabel.numberOfLines = 0
        }
    }

    @IBOutlet weak var msgBackgroundView: UIView! {
        didSet {
            msgBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            msgBackgroundView.layer.cornerRadius = 8
        }
    }

    @IBOutlet weak var avaterImageView: UIImageView! {
        didSet {
            avaterImageView.translatesAutoresizingMaskIntoConstraints = false
            avaterImageView.contentMode = .scaleToFill
            avaterImageView.layer.cornerRadius = 50 / 2
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureLayout() {
        print(message?.content, msgType)

        if let message = message {
            contentLabel.text = message.content
        }

        if let sendBy = sendBy {
            avaterImageView.setImage(urlString: sendBy.profilePhoto)
        }

        switch msgType {
        case .currentUser:
            currentUserMsgType()
        case .other:
            otherMsgType()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        configureLayout()
    }
}

extension MessageCell {
    func currentUserMsgType() {
        avaterImageView.isHidden = true
        msgBackgroundView.backgroundColor = .lightGray
        NSLayoutConstraint.activate([
            // msg background
            msgBackgroundView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.6),
            msgBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),

            // content label
            contentLabel.topAnchor.constraint(equalTo: msgBackgroundView.topAnchor, constant: 10),
            contentLabel.bottomAnchor.constraint(equalTo: msgBackgroundView.bottomAnchor, constant: -10),
            contentLabel.leadingAnchor.constraint(equalTo: msgBackgroundView.leadingAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: msgBackgroundView.trailingAnchor, constant: -10)
        ])
    }

    func otherMsgType() {
        msgBackgroundView.backgroundColor = .red
        NSLayoutConstraint.activate([
            // avater image
            avaterImageView.widthAnchor.constraint(equalToConstant: 50),
            avaterImageView.heightAnchor.constraint(equalToConstant: 50),
            avaterImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            avaterImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30),

            // msg background
            msgBackgroundView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.5),
            msgBackgroundView.leadingAnchor.constraint(equalTo: avaterImageView.trailingAnchor, constant: 10),

            // content label
            contentLabel.topAnchor.constraint(equalTo: msgBackgroundView.topAnchor, constant: 10),
            contentLabel.bottomAnchor.constraint(equalTo: msgBackgroundView.bottomAnchor, constant: -10),
            contentLabel.leadingAnchor.constraint(equalTo: msgBackgroundView.leadingAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: msgBackgroundView.trailingAnchor, constant: -10)
        ])
    }
}
