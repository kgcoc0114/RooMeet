//
//  MessageDetail.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum MessageType: Int, CaseIterable {
    case text = 0
    case image
    case call
}

struct Message: Codable, Hashable {
    let id: String
    let messageType: Int // (0: text, 1: image, 2: call）
    let sendBy: String // userID
    let content: String
    let createdTime: Timestamp
}
