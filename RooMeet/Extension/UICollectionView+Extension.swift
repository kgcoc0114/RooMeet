//
//  UICollectionView+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//
import ESPullToRefresh
import Foundation
import UIKit

extension UICollectionView {
    func addPullToRefresh(_ handler: @escaping ESRefreshHandler) {
        self.es.addPullToRefresh(handler: handler)
    }

    func stopPullToRefresh() {
        self.es.stopPullToRefresh()
    }
}
