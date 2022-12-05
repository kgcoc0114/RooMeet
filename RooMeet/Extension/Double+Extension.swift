//
//  Double+Extension.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/5.
//

import Foundation

extension Double {
    public func roundedTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded()
    }
}
