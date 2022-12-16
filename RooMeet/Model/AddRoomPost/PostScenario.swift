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

//    var editFeeScenario: EditFeeScenario {
//        let billInfo = billInfo ?? BillInfo(
//            water: FeeDetail(),
//            electricity: FeeDetail(),
//            cable: FeeDetail(),
//            internet: FeeDetail(),
//            management: FeeDetail()
//        )
//        switch self {
//        case .create:
//            return EditFeeScenario.create(billInfo)
//        case .edit:
//            return EditFeeScenario.edit(billInfo)
//        }
//    }

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

//    var roomDisplayImages: [UIImage] {
//        let addImage = UIImage.asset(.add)
//        var images = [addImage, addImage, addImage]
//        switch self {
//        case .create:
//            return images
//        case .edit(let room):
//            room.roomImages.enumerated().forEach { index, url in
//                if let imageData = try? Data(contentsOf: url),
//                   let loadedImage = UIImage(data: imageData) {
//                    images[index] = loadedImage
//                }
//            }
//            return images
//        }
//    }
}

protocol PostCell: UICollectionViewCell {
    func configure(container: RMCellContainer)
}

protocol RMCellContainer {}

struct PostDataContainer: RMCellContainer {
    let data: Room?
    let indexPath: IndexPath?

//    var tags: [String] {
//        section?.tags ?? []
//    }
//
//    var selectedTags: [String] {
//        switch section {
//        case .highLight:
//            return postScenario.roomHighLights
//        case .gender:
//            return postScenario.roomGenderRules
//        case .pet:
//            return postScenario.roomPetsRules
//        case .elevator:
//            return postScenario.roomElevatorRules
//        case .cooking:
//            return postScenario.roomCookingRules
//        case .bathroom:
//            return postScenario.roomBathroomRules
//        case .features:
//            return postScenario.roomFeatures
//        default:
//            return []
//        }
//    }
}
