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
    case text
    case image
    case call
    case reservation
}

struct Message: Codable, Hashable {
    let id: String
    let messageType: Int // (0: text, 1: image, 2: call）
    let sendBy: String // userID
    let content: String
    let createdTime: Timestamp
    var reservation: Reservation?
    var imageURL: URL?
}
