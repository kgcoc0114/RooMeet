//
//  Observable.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/18.
//

import Foundation

class Observable<T> {
    typealias Listener = (T) -> Void
    var listener: Listener?

    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func bind(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
