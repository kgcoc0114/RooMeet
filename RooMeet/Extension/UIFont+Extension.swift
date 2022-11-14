//
//  UIFont+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

private enum RMFontName: String {

    case regular = "NotoSansChakma-Regular"
}

extension UIFont {

    static func bold(size: CGFloat) -> UIFont? {
        var descriptor = UIFontDescriptor(name: RMFontName.regular.rawValue, size: size)

        descriptor = descriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold]]
        )

        let font = UIFont(descriptor: descriptor, size: size)

        return font
    }

    static func medium(size: CGFloat) -> UIFont? {
        var descriptor = UIFontDescriptor(name: RMFontName.regular.rawValue, size: size)

        descriptor = descriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.medium]]
        )

        let font = UIFont(descriptor: descriptor, size: size)

        return font
    }

    static func regular(size: CGFloat) -> UIFont? {
        return RMFont(.regular, size: size)
    }

    private static func RMFont(_ font: RMFontName, size: CGFloat) -> UIFont? {
        return UIFont(name: font.rawValue, size: size)
    }
}
