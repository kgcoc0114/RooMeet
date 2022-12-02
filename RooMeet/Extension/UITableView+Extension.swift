//
//  UITableView+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import Foundation
import UIKit
import ESPullToRefresh

extension UITableView {
    func scrollToButtom(at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard numberOfSections > 0 else { return }

        let lastSection = numberOfSections - 1

        guard numberOfRows(inSection: 0) > 0 else { return }

        let lastIndexPath = IndexPath(item: numberOfRows(inSection: lastSection) - 1, section: lastSection)

        scrollToRow(at: lastIndexPath, at: scrollPosition, animated: animated)
    }

    func registerCellWithNib(identifier: String, bundle: Bundle?) {
        let nib = UINib(nibName: identifier, bundle: bundle)
        register(nib, forCellReuseIdentifier: identifier)
    }
}

extension UITableView {
    func addPullToRefresh(_ handler: @escaping ESRefreshHandler) {
        self.es.addPullToRefresh(handler: handler)
    }

    func stopPullToRefresh() {
        self.es.stopPullToRefresh()
    }
}

extension UITableViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}
