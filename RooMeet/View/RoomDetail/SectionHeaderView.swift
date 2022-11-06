//
//  SectionHeaderView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "\(SectionHeaderView.self)"
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
