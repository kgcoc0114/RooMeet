//
//  UIColor+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import Foundation
import UIKit

extension UIColor {
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
