//
//  ChatRoomCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import UIKit

class ChatRoomCell: UITableViewCell {
    static let reuseIdentifier = "\(ChatRoomCell.self)"

    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.textColor = .mainDarkColor
        }
    }

    @IBOutlet weak var contentLabel: UILabel! {
        didSet {
            contentLabel.textColor = .mainDarkColor
            contentLabel.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            userNameLabel.textColor = .mainDarkColor
            userNameLabel.font = UIFont.regularTitle()
        }
    }

    @IBOutlet weak var profileImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        styleCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func styleCell() {
        timeLabel.font = UIFont.regular(size: 10)
        profileImageView.contentMode = .scaleAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
    }

    func layoutCell(_ userName: String, chatRoom: ChatRoom) {
        if let lastMessage = chatRoom.lastMessage {
            contentLabel.text = lastMessage.content
            timeLabel.text = RMDateFormatter.shared.genMessageTimeString(messageTime: lastMessage.createdTime)
        } else {
            contentLabel.text = ""
            timeLabel.text = ""
        }
        if let member = chatRoom.member {
            userNameLabel.text = member.name

            if let profilePhoto = member.profilePhoto {
                profileImageView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
            } else {
                profileImageView.image = UIImage.asset(.roomeet)
            }
        } else {
            userNameLabel.text = "User Name"
            profileImageView.image = UIImage.asset(.roomeet)
        }
    }
}
