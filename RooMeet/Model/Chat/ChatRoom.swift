//
//  ChatRoom.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatMember: Codable, Hashable {
    let id: String
    let profilePhoto: String?
    let name: String
}

struct ChatData: Codable, Hashable {
    let message: Message
    let otherUser: ChatMember?
    let currentUser: ChatMember?
}

struct LastMessage: Codable, Hashable {
    let id: String
    let content: String
    let createdTime: Timestamp

    var toDict: [String: Any] {
        return [
            "id": id as Any,
            "content": content as Any,
            "createdTime": createdTime as Any
        ]
    }
}

struct ChatRoom: Codable, Hashable {
    let id: String
    let members: [String]    // userID
    let messages: [String]? // messageID
    let messagesContent: [Message]? // messageID
    let lastMessage: LastMessage?
    let lastUpdated: Timestamp?
    var member: ChatMember?
}
