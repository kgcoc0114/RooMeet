//
//  MessageDetail.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum MessageType: CaseIterable {
    case text
    case image
}

struct Message: Codable, Hashable {
    let id: String
    let messageType: Int // (0: text, 1: image）
    let sendBy: String // userID
    let content: String
    let createdTime: Timestamp
}
