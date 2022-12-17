//
//  NoDataDisplay.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/10.
//

import Foundation

enum NoDataDisplay {
    case furniture
    case chatRoom
    case home
    case reservation
    case post
    case favorite
    case blockade

    var displayString: String {
        switch self {
        case .furniture:
            return "Tips: 點擊右上角，建立自己的家具清單！"
        case .chatRoom:
            return "目前還沒有聊天紀錄\n點擊房源頁面與有興趣的朋友聊聊吧！"
        case .home:
            return "目前沒有相關房源"
        case .reservation:
            return "Tips: 點擊房源頁面可以向房主發起看房預約"
        case .post:
            return "還沒有貼文唷！可到首頁新增房源找室友！"
        case .favorite:
            return "按下愛心加入我的最愛"
        case .blockade:
            return  "Tips: 尊重 友善 包容 不被黑名單"
        }
    }
}
