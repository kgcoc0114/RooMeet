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
    let mapCenterButtonWidth: CGFloat = 36
    // MARK: -- Intorduction Page
    let profileImageWidth: CGFloat = 120

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

    let compressSizeGap: Double = 100

    let privacyPolicyURL = "https://www.privacypolicies.com/live/e6fe7bef-b07a-4aaa-b5b7-493e4b3deb27"
}

enum EntryType {
    case edit
    case new

    var title: String {
        switch self {
        case .edit:
            return "編輯"
        case .new:
            return "新增"
        }
    }
}

enum EntryPage {
    case fav
    case ownPost

    var title: String {
        switch self {
        case .fav:
            return "Favorites"
        case .ownPost:
            return "My Post"
        }
    }

    var noneLabelString: String {
        switch self {
        case .fav:
            return "按下愛心加入我的最愛"
        case .ownPost:
            return "還沒有貼文唷！可到首頁新增房源找室友！"
        }
    }

    var goHomeButtonTitle: String {
        switch self {
        case .fav:
            return "去逛逛"
        case .ownPost:
            return "新增房源"
        }
    }
}

enum PostVCString: String {
    case submit = "貼文"
    case title = "物件貼文"
    case delete = "刪除貼文"
    case add = "新增貼文"
    case addMessage = "標題、地區與最快可搬入時間為必填欄位"
    case roomSpecAlertMessage = "月租金與坪數為必填欄位"
    case deleteMessage = "確定要刪除貼文嗎？"
    case confirm = "好的"
    case deleteActionTitle = "確定刪除"
    case otherFee = "其他費用"
    case town = "中正區"
    case county = "臺北市"
    case postTitle = "房間出租"
    case cancel = "取消"
}
