//
//  PostalCode.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import Foundation

struct PostalCode: Codable {
    let zip: String
    let city: String
    let area: String
}

struct PostalCodeData: Codable {
    let data: [PostalCode]
}

struct Position: Codable {
    let latitude: Double
    let longitude: Double
}
