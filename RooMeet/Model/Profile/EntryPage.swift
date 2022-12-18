//
//  EntryPage.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/8.
//

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
