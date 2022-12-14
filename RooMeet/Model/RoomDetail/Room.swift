//
//  Room.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


struct Room: Codable, Hashable {
    var roomID: String?
    var userID: String
    var userData: User?
    var createdTime: Timestamp
    var modifiedTime: Timestamp
    var title: String
    var roomImages: [URL]
    var rooms: [RoomSpec]
    var roomFeatures: [String]
    var roomPetsRules: [String]
    var roomHighLights: [String]
    var roomGenderRules: [String]
    var roomCookingRules: [String]
    var roomElevatorRules: [String]
    var roomBathroomRules: [String]
    var town: String
    var county: String
    var address: String
    var lat: Double?
    var long: Double?
    var postalCode: String?
    var billInfo: BillInfo?
    var leaseMonth: Int
    var room: Int
    var parlor: Int
    var movinDate: Date
    var otherDescriction: String?
    var isDeleted: Bool = false

    var roomMinPrice: Int?
    var billInfoList: [RoomDetailFee]? {
        var tmpList: [RoomDetailFee] = []
        guard let billInfo = billInfo else {
            return tmpList
        }

        BillType.allCases.forEach { billType in
            let feeDetail = billType.feeDetail(billInfo: billInfo)

            if feeDetail.paid == true {
                let roomDetailFee = RoomDetailFee(billType: billType, feeDatail: feeDetail)
                tmpList.append(roomDetailFee)
            }
        }
        return tmpList
    }

    func getRoomMinPrice() -> Int? {
        guard
            let firstRoom = rooms.first,
            firstRoom.price != nil else {
            return -1
        }

        let minRoom = rooms.min { $0.price! < $1.price! }
        if let minRoom = minRoom {
            return minRoom.price
        }
        return -1
    }
}


struct RoomSpec: Codable, Hashable {
    var roomType: String?
    var price: Int?
    var space: Double?
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
}

struct BillInfo: Codable, Hashable {
    var water: FeeDetail
    var electricity: FeeDetail
    var cable: FeeDetail
    var internet: FeeDetail
    var management: FeeDetail

    private func genString(data: FeeDetail, type: FeeType) -> String {
        var desc: String
        if data.paid == true {
            let typeString = type == .electricity ? "??????" : "??????"
            let unitString = type == .electricity ? "???/???" : "???"
            let priceString = "\(data.isGov == true ? typeString : String(describing: data.fee))"
            var affordString: String
            if let afford = AffordType(rawValue: data.affordType) {
                affordString = " - \(afford.description)"
            } else {
                affordString = ""
            }
            desc = "\(priceString) " + "\(data.isGov == true ? "" : unitString)" + "\(affordString)"
        } else {
            desc = "????????????"
        }
        return desc
    }
}

struct FeeDetail: Codable, Hashable {
    var paid: Bool? = false
    var fee: Double?
    var isGov: Bool?
    var affordType: String = "separate"

    var description: String {
        if paid == false {
            return "????????????"
        } else {
            return String(describing: fee)
        }
    }
}

enum AffordType: String, Hashable, CaseIterable {
    case separate
    case share

    var description: String {
        switch self {
        case .separate: return "????????????"
        case .share: return "????????????"
        }
    }

    var index: Int {
        switch self {
        case .separate: return 0
        case .share: return 1
        }
    }
}

struct RoomList: Codable {
    let data: [Room]
}

enum BillType: String, CaseIterable {
    case water
    case electricity
    case cable
    case internet
    case management


    var image: UIImage {
        switch self {
        case .water:
            return UIImage(systemName: "drop")!
        case .electricity:
            return UIImage(systemName: "bolt")!
        case .cable:
            return UIImage(systemName: "tv")!
        case .internet:
            return UIImage(systemName: "globe")!
        case .management:
            return UIImage(systemName: "figure.stand")!
        }
    }

    var unitString: String {
        switch self {
        case .water, .cable, .internet, .management:
            return ""
        case .electricity:
            return "???/???"
        }
    }

    var title: String {
        switch self {
        case .water:
            return "???"
        case .electricity:
            return "???"
        case .cable:
            return "?????????"
        case .internet:
            return "??????"
        case .management:
            return "?????????"
        }
    }

    var separateString: String {
        switch self {
        case .water, .cable, .internet, .management:
            return "????????????"
        case .electricity:
            return "????????????"
        }
    }

    func feeDetail(billInfo: BillInfo) -> FeeDetail {
        switch self {
        case .water:
            return billInfo.water
        case .electricity:
            return billInfo.electricity
        case .cable:
            return billInfo.cable
        case .internet:
            return billInfo.internet
        case .management:
            return billInfo.management
        }
    }
}
