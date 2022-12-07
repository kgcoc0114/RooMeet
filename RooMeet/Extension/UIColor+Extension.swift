//
//  UIColor+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import Foundation
import UIKit


private enum RMColor: String {
    case mainColor
    case mainLightColor
    case mainDarkColor
    case mainDarkGrayColor
    case mainBackgroundColor
    case subTitleColor
    case subTitleOrangeColor
    case subTitleRedColor
    case subTitleRedBGColor
    case subColor
    case msgBackgroundColor
}

extension UIColor {
    static let mainColor = RMColor(.mainColor)
    static let mainLightColor = RMColor(.mainLightColor)
    static let mainBackgroundColor = RMColor(.mainBackgroundColor)
    static let subTitleColor = RMColor(.subTitleColor)
    static let subColor = RMColor(.subColor)
    static let mainDarkColor = RMColor(.mainDarkColor)
    static let msgBackgroundColor = RMColor(.msgBackgroundColor)
    static let subTitleOrangeColor = RMColor(.subTitleOrangeColor)
    static let subTitleRedColor = RMColor(.subTitleRedColor)
    static let subTitleRedBGColor = RMColor(.subTitleRedBGColor)
    static let mainDarkGrayColor = RMColor(.mainDarkGrayColor)

    private static func RMColor(_ color: RMColor) -> UIColor {
        guard let color = UIColor(named: color.rawValue) else { return .darkGray}
        return color
    }

    static func hexColor(hex: String) -> UIColor {
        if hex[hex.startIndex] == "#" && hex.count == 7 {
            var hexString: String = hex
            hexString.remove(at: hexString.startIndex)
            guard let result = UInt32(hexString, radix: 16) else {
                return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
            return UIColor(
                red: CGFloat(((result & 0xFF0000) >> 16)) / 255,
                green: CGFloat(((result & 0x00FF00) >> 8)) / 255,
                blue: CGFloat((result & 0x0000FF)) / 255,
                alpha: 1
            )
        } else {
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
}
