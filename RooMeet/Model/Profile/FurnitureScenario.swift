//
//  FurnitureScenario.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/10.
//

import Foundation

enum FurnitureScenario {
    case create(Furniture)
    case edit(Furniture)

    var furniture: Furniture {
        switch self {
        case .create(let data):
            return data
        case .edit(let data):
            return data
        }
    }

    var lengthString: String {
        switch self {
        case .create:
            return ""
        case .edit(let furniture):
            return furniture.length == nil ? "" : "\(furniture.length!)cm"
        }
    }

    var heightString: String {
        switch self {
        case .create:
            return ""
        case .edit(let furniture):
            return furniture.height == nil ? "" : "\(furniture.height!)cm"
        }
    }

    var widthString: String {
        switch self {
        case .create:
            return ""
        case .edit(let furniture):
            return furniture.width == nil ? "" : "\(furniture.width!)cm"
        }
    }
}
