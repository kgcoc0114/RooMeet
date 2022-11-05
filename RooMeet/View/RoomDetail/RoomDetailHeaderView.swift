//
//  RoomDetailHeaderView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/5.
//

import UIKit

class RoomDetailHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "\(RoomDetailHeaderView.self)"
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.systemFont(ofSize: 25)
    }

    func configureView(title: String) {
        titleLabel.text = title
    }
}
