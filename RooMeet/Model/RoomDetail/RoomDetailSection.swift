//
//  RoomDetailSection.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/8.
//

import Foundation
import UIKit

enum RoomDetailSection: CaseIterable {
    case images
    case basicInfo
    case reservationDays
    case reservationPeriod
    case map
    case highLight
    case gender
    case pet
    case elevator
    case cooking
    case bathroom
    case features
    case feeDetail


    var title: String {
        switch self {
        case .images:
            return ""
        case .basicInfo:
            return ""
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
        case .feeDetail:
            return "費用明細"
        case .reservationDays:
            return "預約看房"
        case .reservationPeriod:
            return ""
        case .map:
            return "地圖"
        }
    }

    var layoutSection: NSCollectionLayoutSection {
        switch self {
        case .basicInfo, .highLight, .gender, .pet, .elevator, .cooking, .bathroom, .features:
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(1)), subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            return section
        case .feeDetail:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(1)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(1)
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

            // SectionHeader
            section.boundarySupplementaryItems = [createSectionHeader()]

            return section
        case .images:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(300)),
                subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        case .reservationDays:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth((1 / CGFloat(RMConstants.shared.reservationDays))),
                    heightDimension: .fractionalHeight(1.0)
                )
            )
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(75)),
                subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

            // SectionHeader
            section.boundarySupplementaryItems = [createSectionHeader()]
            return section
        case .reservationPeriod:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(60)),
                subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

            return section
        case .map:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(150)),
                subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

            // SectionHeader
            section.boundarySupplementaryItems = [createSectionHeader()]
            return section
        }
    }

    private func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        return header
    }
}

enum RoomDetailItem: Hashable {
    case images(Room)
    case basicInfo(Room)
    case highLight(Room)
    case gender(Room)
    case pet(Room)
    case elevator(Room)
    case cooking(Room)
    case bathroom(Room)
    case features(Room)
    case feeDetail(RoomDetailFee)
    case reservationDays(DateComponents)
    case reservationPeriod(Room)
    case map(Room)


    var cellIdentifier: String {
        switch self {
        case .images:
            return RoomImagesCell.reuseIdentifier
        case .basicInfo:
            return RoomBasicCell.reuseIdentifier
        case .reservationDays:
            return BookingDateCell.reuseIdentifier
        case .reservationPeriod:
            return BookingPeriodCell.reuseIdentifier
        case .map:
            return RoomMapCell.reuseIdentifier
        case .highLight, .gender, .elevator, .cooking, .bathroom, .features, .pet:
            return ItemsCell.reuseIdentifier
        case .feeDetail:
            return RoomFeeCell.reuseIdentifier
        }
    }

    var container: RoomDetailContainer {
        switch self {
        case .feeDetail(let roomDetailFee):
            return FeeDetailContainer(roomDetailFee: roomDetailFee)
        case .reservationDays(let dateComponents):
            return BookingContainer(bookingDate: dateComponents)
        case .images(let room),
            .basicInfo(let room),
            .reservationPeriod(let room),
            .map(let room):
            return RoomContainer(room: room)
        case .highLight(_),
                .gender(_),
                .pet(_),
                .elevator(_),
                .cooking(_),
                .bathroom(_):
            return RoomTagContainer(
                tags: self.tags,
                title: self.title,
                mainColor: .mainColor
            )
        case .features(_):
            return RoomTagContainer(
                tags: self.tags,
                title: self.title,
                mainColor: .subTitleColor
            )
        }
    }

    
    var tags: [String] {
        switch self {
        case .highLight(let room):
            return room.roomHighLights
        case .gender(let room):
            return room.roomGenderRules
        case .pet(let room):
            return room.roomPetsRules
        case .elevator(let room):
            return room.roomElevatorRules
        case .cooking(let room):
            return room.roomCookingRules
        case .bathroom(let room):
            return room.roomBathroomRules
        case .features(let room):
            return room.roomFeatures
        default:
            return []
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
}

protocol RoomDetailCell: UICollectionViewCell {
    func configure(container: RoomDetailContainer)
}

protocol RoomDetailContainer {}

struct RoomContainer: RoomDetailContainer {
    let room: Room
}

struct FeeDetailContainer: RoomDetailContainer {
    let roomDetailFee: RoomDetailFee
}

struct BookingContainer: RoomDetailContainer {
    let bookingDate: DateComponents
}

struct RoomTagContainer: RoomDetailContainer {
    let tags: [String]
    let title: String
    let mainColor: UIColor
    let lightColor: UIColor = .mainBackgroundColor
}
