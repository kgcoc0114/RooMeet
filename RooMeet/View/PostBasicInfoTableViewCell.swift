//
//  PostBasicInfoTableViewCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class PostBasicInfoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "\(PostBasicInfoTableViewCell.self)"

    @IBOutlet weak var roomCountView: NumberPickerView!
    @IBOutlet weak var parlorCountView: NumberPickerView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        roomCountView.configurateLayout(placeholder: "room count")
        parlorCountView.configurateLayout(placeholder: "parlor count")

        // Configure the view for the selected state
    }
    
}
