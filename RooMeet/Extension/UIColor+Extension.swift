//
//  UIColor+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import Foundation
import UIKit

enum RMColor: String {
    case B1
    case B2
    case B3
    case B4
    case B5
    case B6
    case G1
    case palePink
    case snow
    case darkSienna

    var hex: String {
        switch self {
        case .B1:
            return "#605856"
        case .B2:
            return "#1c6e8c"
        case .B3:
            return "#274156"
        case .B4:
            return "#d89a9e"
        case .B5:
            return "#fac748"
        case .B6:
            return "#58A4B0"
        case .G1:
            return "#D4DCCD"
        case .snow:
            return "#f9f0f1"
        case .palePink:
            return "#EED3D5"
        case .darkSienna:
            return "#2C1115"
        }
    }
}


extension UIColor {

    static let B1 = RMColor(.B1)

    static let B2 = RMColor(.B2)

    static let B4 = RMColor(.B4)

    static let B5 = RMColor(.B6)

    static let messageCUColor = RMColor(.palePink)

    static let messageOUColor = UIColor.white

    static let messageBackgroundColor = RMColor(.darkSienna)


    // swiftlint:enable identifier_name

    private static func RMColor(_ color: RMColor) -> UIColor? {
        return hexColor(hex: color.hex)//UIColor(named: color.rawValue)
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
