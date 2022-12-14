//
//  Furniture.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Furniture: Codable {
    var id: String?
    var title: String?
    var imageURL: String?
    var length: Int?
    var height: Int?
    var width: Int?
    var userID: String?
    var createdTime: Timestamp?
}
