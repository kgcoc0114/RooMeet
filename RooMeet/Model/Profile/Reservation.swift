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
    var createdTime: Timestamp
    var modifiedTime: Timestamp?
    var roomDetail: Room?
    var isDeleted: Bool? = false
}

enum AcceptedStatus: String, CaseIterable {
    case waiting
    case cancel
    case accept
    case answer

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

    var content: String {
        switch self {
        case .waiting:
            return "預約待回覆"
        case .cancel:
            return "預約已取消"
        case .accept:
            return "預約已接受"
        case .answer:
            return "預約已回覆"
        }
    }

    var tagColor: UIColor {
        switch self {
        case .waiting:
            return UIColor.hexColor(hex: "#94B9AF")
        case .cancel:
            return UIColor.hexColor(hex: "#D89A9E")
        case .accept:
            return UIColor.hexColor(hex: "#f7cb15")
        case .answer:
            return UIColor.hexColor(hex: "")
        }
    }
}
