//
//  PostSection.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/5.
//

enum PostSection: CaseIterable {
    case basic
    case roomSpec
    case highLight
    case gender
    case pet
    case elevator
    case cooking
    case bathroom
    case features
    case feeHeader
    case feeDetail
    case images

    var title: String {
        switch self {
        case .highLight:
            return "亮點"
        case .gender:
            return "租客性別"
        case .pet:
            return "寵物"
        case .elevator:
            return "電梯"
        case .cooking:
            return "開伙"
        case .features:
            return "設施"
        case .bathroom:
            return "衛浴"
        default:
            return ""
        }
    }

    var tags: [String] {
        switch self {
        case .highLight:
            return RMConstants.shared.roomHighLights
        case .gender:
            return RMConstants.shared.roomGenderRules
        case .pet:
            return RMConstants.shared.roomPetsRules
        case .elevator:
            return RMConstants.shared.roomElevatorRules
        case .cooking:
            return RMConstants.shared.roomCookingRules
        case .features:
            return RMConstants.shared.roomFeatures
        case .bathroom:
            return RMConstants.shared.roomBathroomRules
        default:
            return []
        }
    }
}
