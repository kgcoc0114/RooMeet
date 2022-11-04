//
//  UIImageView+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import Foundation
import UIKit

extension UIImageView {

    func setImage(urlString: String) {
        if let imageUrl = URL(string: urlString) {
            URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, response, error) in
                if error != nil {
                    print("Download Image Task Fail: \(error!.localizedDescription)")
                } else if let imageData = data {
                    DispatchQueue.main.async {
                        self.image = UIImage(data: imageData)
                    }
                }
            }).resume()
        }
    }
}
