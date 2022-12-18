//
//  ChatCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/9.
//

import UIKit


protocol ChatCell: UITableViewCell {
    func configure(for data: ChatData)
}

enum ChatItem: Hashable {
    case message(ChatData)

    var chatData: ChatData {
        switch self {
        case .message(let chatData):
            return chatData
        }
    }

    var cellIdentifier: String {
        switch self {
        case .message(let chatData):
            guard let messageType = MessageType(rawValue: chatData.message.messageType) else {
                return ""
            }

            switch messageType {
            case .text:
                if chatData.message.sendBy == UserDefaults.id {
                    return CUTextCell.identifier
                }
                return OUTextCell.identifier
            case .image:
                if chatData.message.sendBy == UserDefaults.id {
                    return CUImageCell.identifier
                }
                return OUImageCell.identifier
            case .call:
                if chatData.message.sendBy == UserDefaults.id {
                    return CUCallCell.identifier
                }
                return OUCallCell.identifier
            case .reservation:
                if chatData.message.sendBy == UserDefaults.id {
                    return CUReservationCell.identifier
                }
                return OUReservationCell.identifier
            }
        }
    }
}
