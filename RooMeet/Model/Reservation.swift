//
//  Reservation.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Reservation: Codable, Hashable {
    var id: String
    var roomID: String?
    var requestTime: Timestamp?
    var period: String?
    var sender: String?
    var receiver: String?
    var acceptedStatus: String?
    var createdTime: Timestamp?
    var modifiedTime: Timestamp?
    var roomDetail: Room?
}

enum AcceptedStatus: CaseIterable {
    case waiting
    case cancel // 取消邀請
    case accept // 同意
    case answer // 回覆過的 waiting 訊息

    var description: String {
        switch self {
        case .waiting:
            return "waiting"
        case .cancel:
            return "cancel"
        case .accept:
            return "accept"
        case .answer:
            return "answer"
        }
    }
}
