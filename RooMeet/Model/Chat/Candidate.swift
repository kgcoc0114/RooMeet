//
//  Candidate.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/7.
//

import Foundation

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
}

struct Offer: Codable {
    var sdp: String
    var type: Int
}

enum CallType: String {
    case offer = "offer"
    case answer = "answer"
}
