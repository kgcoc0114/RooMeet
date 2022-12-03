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

extension UICollectionView {
    func registerCellWithNib(reuseIdentifier: String, bundle: Bundle?) {
        let nib = UINib(nibName: reuseIdentifier, bundle: bundle)
        register(nib, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func registerHeaderWithNib(reuseIdentifier: String, bundle: Bundle?) {
        let nib = UINib(nibName: reuseIdentifier, bundle: nil)
        register(
            nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: reuseIdentifier)
    }
}

extension UICollectionReusableView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
