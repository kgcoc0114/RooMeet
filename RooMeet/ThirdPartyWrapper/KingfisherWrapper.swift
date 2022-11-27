//
//  KingfisherWrapper.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import Kingfisher
import UIKit

extension UIImageView {
    func loadImage(_ urlString: String?, placeHolder: UIImage? = nil) {
        guard let urlString = urlString else {
            self.image = placeHolder
            return
        }
        let url = URL(string: urlString)
        self.kf.setImage(with: url, placeholder: placeHolder)
    }
}
