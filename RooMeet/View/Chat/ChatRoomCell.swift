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
        userNameLabel.text = chatRoom.member?.name ?? ""
        contentLabel.text = chatRoom.lastMessage?.content ?? ""
        print(chatRoom.lastMessage?.createdTime)
        print(chatRoom.member?.profilePhoto)
        timeLabel.text = "..."
        profileImageView.setImage(urlString: (chatRoom.member?.profilePhoto ??  "https://github.com/developerjet/JetChat/raw/master/ScreenShot/JetChatSmall.png")!)
    }
}
