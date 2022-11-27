//
//  ReportEvent.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

struct ReportEvent: Codable {
    let reportUser: String
    let type: String
    let reportedID: String?
    let createdTime: Timestamp
}
