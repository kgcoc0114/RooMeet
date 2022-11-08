//
//  Candidate.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/7.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Candidate: Codable {
    let candidate: String
    let sdpMLineIndex: Int
    let sdpMid: String
}

struct Call: Codable {
    var offer: Offer
    var answer: Offer?
    var members: [String]
    var caller: String
    var status: String
    var startTime: Timestamp?
    var endTime: Timestamp?
    var callTime: String?
}

struct Offer: Codable {
    var sdp: String
    var type: Int
}

enum CallType {
    case offer
    case answer

    var description: String {
        switch self {
        case .offer: return "offer"
        case .answer: return "answer"
        }
    }
}
