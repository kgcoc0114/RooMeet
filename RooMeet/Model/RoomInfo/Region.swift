//
//  Region.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import Foundation
struct Region: Codable {
    let county: String
    let town: [String]
}

extension Region {
    static let taipei = Region(county: "台北市", town: ["大安區", "大同區", "中正區"])
    static let newTaipei = Region(county: "新北市", town: ["三重區", "板橋區"])
}

struct RegionData: Codable {
    let data: [Region]
}
