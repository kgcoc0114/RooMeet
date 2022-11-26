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

private enum RMFontSize: CGFloat {
    case title1 = 20
    case title = 18
    case subTitle = 16
    case text = 14
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

    static func regularTitle() -> UIFont {
        return RMFont(.regular, size: RMFontSize.title.rawValue)
    }

    static func regularTitle1() -> UIFont {
        return RMFont(.regular, size: RMFontSize.title1.rawValue)
    }

    static func regularSubTitle() -> UIFont {
        return RMFont(.regular, size: RMFontSize.subTitle.rawValue)
    }

    static func regularText() -> UIFont {
        return RMFont(.regular, size: RMFontSize.text.rawValue)
    }

    static func boldTitle() -> UIFont {
        return self.bold(size: RMFontSize.title.rawValue) ?? UIFont.systemFont(ofSize: 18)
    }

    static func boldSubTitle() -> UIFont {
        return self.bold(size: RMFontSize.subTitle.rawValue) ?? UIFont.systemFont(ofSize: 16)
    }

    static func boldText() -> UIFont {
        return self.bold(size: RMFontSize.text.rawValue) ?? UIFont.systemFont(ofSize: 14)
    }


    private static func RMFont(_ font: RMFontName, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: 16)
    }
}
