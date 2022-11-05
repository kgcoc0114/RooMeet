//
//  CurrentUserMsgCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit

class CurrentUserMsgCell: UITableViewCell {
    static let reuseIdentifier = "\(CurrentUserMsgCell.self)"

    var msgType: MsgType = .currentUser
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
    }
}
