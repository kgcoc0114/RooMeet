//
//  PostScenario.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/11.
//

import FirebaseFirestore

enum PostScenario: Hashable {
    case create
    case edit(Room)

    var pageTitle: String {
        switch self {
        case .create:
            return "新增"
        case .edit:
            return "編輯"
        }
    }

    var roomSpecList: [RoomSpec] {
        switch self {
        case .create:
            return [RoomSpec()]
        case .edit(let room):
            return room.rooms
        }
    }

    var roomHighLights: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomHighLights
        }
    }

    var roomGenderRules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomGenderRules
        }
    }

    var roomPetsRules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomPetsRules
        }
    }

    var roomElevatorRules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomElevatorRules
        }
    }

    var roomCookingRules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomCookingRules
        }
    }

    var roomFeatures: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomFeatures
        }
    }

    var roomBathroomRules: [String] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomBathroomRules
        }
    }

    var billInfo: BillInfo? {
        switch self {
        case .create:
            return nil
        case .edit(let room):
            return room.billInfo
        }
    }

    var postBasicData: PostBasicData? {
        switch self {
        case .create:
            return nil
        case .edit(let room):
            return PostBasicData(
                title: room.title,
                county: room.county,
                town: room.town,
                address: room.address,
                room: room.room,
                parlor: room.parlor,
                leaseMonth: room.leaseMonth,
                movinDate: room.movinDate
            )
        }
    }

    var title: String? {
        return postBasicData?.title ?? nil
    }

    var address: String? {
        return postBasicData?.address ?? nil
    }

    var region: String? {
        if let county = postBasicData?.county,
           let town = postBasicData?.town {
            return "\(county)\(town)"
        }
        return nil
    }

    var parlor: String? {
        return postBasicData?.parlor == nil ? nil : String(describing: postBasicData?.parlor)
    }

    var roomCount: String? {
        return postBasicData?.room == nil ? nil : String(describing: postBasicData?.room)
    }


    var movinDate: String? {
        return postBasicData?.movinDate == nil ? nil : RMDateFormatter.shared.dateString(date: (postBasicData?.movinDate)!)
    }

    var leaseMonth: String? {
        guard let leaseMonth = postBasicData?.leaseMonth else { return nil }
        if leaseMonth >= 12 {
            let year = leaseMonth / 12
            return "\(year) 年"
        } else {
            return "\(leaseMonth) 月"
        }
    }

    var roomImagesUrl: [URL] {
        switch self {
        case .create:
            return []
        case .edit(let room):
            return room.roomImages
        }
    }

    var otherDescriction: String? {
        switch self {
        case .create:
            return nil
        case .edit(let room):
            return room.otherDescriction
        }
    }

    var latitude: Double? {
        switch self {
        case .create:
            return nil
        case .edit(let room):
            return room.lat
        }
    }

    var longitude: Double? {
        switch self {
        case .create:
            return nil
        case .edit(let room):
            return room.long
        }
    }

    var createdTime: Timestamp {
        switch self {
        case .create:
            return Timestamp()
        case .edit(let room):
            return room.createdTime
        }
    }
}

protocol PostCell: UICollectionViewCell {
    func configure(container: RMCellContainer)
}

protocol RMCellContainer {}

struct PostDataContainer: RMCellContainer {
    let room: Room?
    let indexPath: IndexPath
    let roomSpecList: [RoomSpec]?
}
