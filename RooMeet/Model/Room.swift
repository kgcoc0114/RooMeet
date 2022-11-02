//
//  Room.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Room: Codable {
    var roomID: String
    var userID: String
    var createdTime: Timestamp
    var modifiedTime: Timestamp
    var title: String
    var roomImages: [URL]
    var rooms: [RoomSpec]
    var roommateGender: Int // (0: male, 1: female, 2: nonBinary, 3: all)
    var rules: [String]
    var publicAmenities: [String]
    var address: Address
//    var currentLivingInfo: CurrentLivingInfo
    var billInfo: BillInfo?
    var lease: Double
    var movinDate: Date
    var otherDescriction: String?
//    var status: String
    var isDeleted: Bool
}

struct RoomSpec: Codable {
    var roomType: [Int]?
    var price: Int?
    var space: Double?
    var people: Int?
    var amenities: [String]?
}

struct CurrentLivingInfo: Codable {
    let number: Int
    let descriction: String
}

struct Address: Codable {
    let town: String
    let county: String
    let address: String
    let lat: Double
    let long: Double
//    let transportation: [Transportation]
}

struct Transportation: Codable {
    let transType: Int // (0: 公車站, 1: 捷運站）
    let distance: Double
    let site: String
}

struct BillInfo: Codable {
    var water: FeeDetail
    var electricity: FeeDetail
    var cable: FeeDetail
    var internet: FeeDetail
    var management: FeeDetail
    
    private func genString(data: FeeDetail, type: FeeType) -> String {
        var desc: String
        if data.paid == true {
            let typeString = type == .electricity ? "台電" : "台水"
            let unitString = type == .electricity ? "度/元" : "元"
            let priceString = "\(data.isGov == true ? typeString : String(describing: data.fee))"
            var affordString: String
            if let affordType = data.affordType,
               let afford = AffordType(rawValue: affordType) {
                affordString = " - \(afford.description)"
            } else {
                affordString = ""
            }
            desc = "\(priceString) " + "\(data.isGov == true ? "" : unitString)" + "\(affordString)"
        } else {
            desc = "無須支付"
        }
        return desc
    }

    var description : String {
        return """
電費：\(self.genString(data: electricity, type: .electricity))\n
水費：\(self.genString(data: water, type: .water))\n
第四臺：\(self.genString(data: cable, type: .cable))\n
網路費：\(self.genString(data: internet, type: .internet))\n
管理費：\(self.genString(data: management, type: .management))\n
"""
    }
}

struct FeeDetail: Codable {
    var paid: Bool? = false
    var fee: Double?
    var isGov: Bool?
    var affordType: String?
    
    var description : String {
        if paid == false {
            return "無須支付"
        } else {
            return String(describing: fee)
        }
    }
}

enum AffordType: String {
    case sperate = "sperate"
    case share = "share"
    
    var description : String {
        switch self {
        case .sperate: return "獨立量表"
        case .share: return "費用均分"
        }
    }
}
