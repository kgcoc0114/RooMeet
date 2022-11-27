//
//  RMConstants.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit
import MapKit

class RMConstants {
    static let shared = RMConstants()

    var currentPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 25.03320617048529, longitude: 121.56449873729362)

    let screenVerticalPadding: CGFloat = 30

    let buttonCornerRadius: CGFloat = 28
    let dataPickerCornerRadius: CGFloat = 10
    let tagCornerRadius: CGFloat = 8
    let reservationDays: Int = 6
    let textFontSize: CGFloat = 12
    let title3FontSize: CGFloat = 15
    let title2FontSize: CGFloat = 20
    let title2FontColor = UIColor.hexColor(hex: "#363130")
    let mapCenterButtonWidth: CGFloat = 36
    let mainColor = UIColor.hexColor(hex: "#43736F")
    let mainLightColor = UIColor.hexColor(hex: "#F3F3F5")
    let mainLightBackgroundColor = UIColor.hexColor(hex: "#DFE4E5")
    // Intorduction Page
    let profileImageWidth: CGFloat = 120
    // MARK: - Room Detail Page

    // MARK: - Chat Page
    // MARK: -- message
    let avatarImageWidth: CGFloat = 40
    let messageImageWidth: CGFloat = 120
    let messageCornerRadius: CGFloat = 10
    let OULeading: CGFloat = 10
    let CUTrailing: CGFloat = -10
    let dateTimeFontSize: CGFloat = 9

    let reservationStatusFontSize: CGFloat = 12

    let yesterday = "昨天"

    // MARK: - room details
    let roomFeatures = [
        "冰箱", "熱水器", "網路", "陽台", "洗衣機",
        "床", "天然瓦斯", "電梯", "電視", "衣櫃",
        "沙發", "機械車位", "冷氣", "第四台", "桌椅"
    ]

    let roomHighLights = ["近捷運", "近公車", "近UBike", "近商圈"]

    let roomPetsRules = ["不可寵", "可養貓", "可養狗", "可議"]
    let roomCookingRules = ["可做飯", "不可做飯"]
    let roomElevatorRules = ["有電梯", "無電梯"]
    let roomGenderRules = ["男女不限", "限男", "限女"]
    let roomBathroomRules = ["獨立衛浴", "公用衛浴"]

    let compressSizeGap: Double = 80

    let privacyPolicyURL = "https://www.privacypolicies.com/live/e6fe7bef-b07a-4aaa-b5b7-493e4b3deb27"
}

enum EntryType {
    case edit
    case new
}
