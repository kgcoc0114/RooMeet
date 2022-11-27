//
//  RulesCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class RulesCell: UICollectionViewCell {
    static let reuseIdentifier = "\(RulesCell.self)"

    @IBOutlet weak var ruleButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func layoutCell(title: String) {
        ruleButton.setTitle(title, for: .normal)
    }
}
