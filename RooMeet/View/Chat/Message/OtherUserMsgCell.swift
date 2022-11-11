//
//  OtherUserMsgCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

enum MsgType {
    case currentUser
    case other

    var backgroundColor: UIColor {
        switch self {
        case .currentUser:
            return UIColor.lightGray
        case .other:
            return UIColor.systemTeal
        }
    }
}

class OtherUserMsgCell: UITableViewCell {
    static let reuseIdentifier = "\(OtherUserMsgCell.self)"

    var msgType: MsgType = .other
    var message: Message?
    var sendBy: ChatMember?

    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.translatesAutoresizingMaskIntoConstraints = false
            contentTextView.backgroundColor = msgType.backgroundColor
            contentTextView.layer.cornerRadius = 8
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleToFill
            avatarView.layer.cornerRadius = 50 / 2
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureLayout() {
        if let message = message {
            contentTextView.text = message.content
        }

        if let sendBy = sendBy {
            avatarView.setImage(urlString: sendBy.profilePhoto)
        }
    }
}
