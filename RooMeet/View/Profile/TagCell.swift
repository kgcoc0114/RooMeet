//
//  TagCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit

class TagCell: UICollectionViewCell {
    static let identifier = "TagCell"

    @IBOutlet weak var tagButton: UIButton! {
        didSet{
            tagButton.layer.cornerRadius = 5
            tagButton.tintColor = .white
            tagButton.backgroundColor = .blue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func styleCell(data: String) {
        tagButton.setTitle(data, for: .normal)
    }
    
    func configureCell(data: String) {
        tagButton.setTitle(data, for: .normal)
    }
}
