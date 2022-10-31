//
//  PostHeaderView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class PostHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "\(PostHeaderView.self)"

    @IBOutlet weak var editAction: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
