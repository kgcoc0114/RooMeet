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
}
