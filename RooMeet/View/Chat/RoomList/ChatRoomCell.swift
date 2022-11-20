//
//  ChatRoomCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import UIKit

class ChatRoomCell: UITableViewCell {
    static let reuseIdentifier = "\(ChatRoomCell.self)"

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        styleCell()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func styleCell() {
        userNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        contentLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        profileImageView.contentMode = .scaleToFill
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
                profileImageView.setImage(urlString: profilePhoto)
            } else {
                profileImageView.image = UIImage.asset(.profile_user)
            }

        } else {
            userNameLabel.text = ""
            profileImageView.setImage(urlString: "https://github.com/developerjet/JetChat/raw/master/ScreenShot/JetChatSmall.png")
        }
    }
}
