//
//  UITableView+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import Foundation
import UIKit

extension UITableView {
    func scrollToButtom(at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard numberOfSections > 0 else { return }

        let lastSection = numberOfSections - 1

        guard numberOfRows(inSection: 0) > 0 else { return }

        let lastIndexPath = IndexPath(item: numberOfRows(inSection: lastSection) - 1, section: lastSection)

        scrollToRow(at: lastIndexPath, at: scrollPosition, animated: animated)
    }
}
