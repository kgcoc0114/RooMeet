//
//  UIImage+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import Foundation
import UIKit

extension UIImage {
    func scale(scaleFactor: CGFloat = 0.1) -> UIImage {
        let newHeight = self.size.height * scaleFactor
        let newWidth = self.size.width * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }

    static func asset(_ asset: ImageAsset) -> UIImage {
        return UIImage(named: asset.rawValue)!
    }
}

enum ImageAsset: String {
    // swiftlint:disable identifier_name
    case gender_male
    case gender_female
    case gender_non_binary
    case user
    case home
    case dollar
    case profile_user
    case add_image
                
}

extension UIImage {

    public enum DataUnits: String {
        case byte, kilobyte, megabyte, gigabyte
    }

    func getSizeIn(_ type: DataUnits)-> Double {

        guard let data = self.pngData() else {
            return 0
        }

        var size: Double = 0.0

        switch type {
        case .byte:
            size = Double(data.count)
        case .kilobyte:
            size = Double(data.count) / 1024
        case .megabyte:
            size = Double(data.count) / 1024 / 1024
        case .gigabyte:
            size = Double(data.count) / 1024 / 1024 / 1024
        }

        print(String(format: "%.2f", size))

        return size
    }
}
