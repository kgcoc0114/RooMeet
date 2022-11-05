//
//  RoomBasicCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomBasicCell: UICollectionViewCell {
    static let reuseIdentifier = "\(RoomBasicCell.self)"

    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(area: String, roomSpecs: [RoomSpec], title: String) {
        priceLabel.text = genPriceString(roomSpecs: roomSpecs)
        areaLabel.text = area
        titleLabel.text = title
    }

    func genPriceString(roomSpecs: [RoomSpec]) -> String {
        if !roomSpecs.isEmpty {
            let minPriceItem = roomSpecs.min { $0.price! > $1.price! }

            let maxPriceItem = roomSpecs.max { $0.price! < $1.price! }

            if let minPrice = minPriceItem,
               let maxPrice = maxPriceItem,
               let min = minPrice.price,
               let max = maxPrice.price {
                if min == max {
                    return "\(min) 元/月"
                } else {
                    return "\(min) - \(max) 元/月"
                }
            }
        }
        return "請私訊聊聊"
    }
}
