//
//  PostSection.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/5.
//
import UIKit

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

    var cellIdentifier: String {
        switch self {
        case .basic:
            return PostBasicCell.reuseIdentifier
        case .roomSpec:
            return RoomSpecCell.reuseIdentifier
        case .highLight, .gender, .pet, .elevator, .cooking, .features, .bathroom:
            return ItemsCell.reuseIdentifier
        case .feeHeader:
            return OtherFeeHeaderCell.reuseIdentifier
        case .images:
            return PostImageCell.reuseIdentifier
        case .feeDetail:
            return FeeDetailCell.reuseIdentifier
        }
    }

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

    var sectionLayout: NSCollectionLayoutSection {
        switch self {
        case .images:
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.33),
                heightDimension: .absolute(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20)
            return section
        case .roomSpec:
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(120))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(120))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            return section
        default:
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(1))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            return section
        }
    }
}
