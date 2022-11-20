////
////  MultipleChooseCell.swift
////  RooMeet
////
////  Created by kgcoc on 2022/10/31.
////
//
//import UIKit
//
//class MultipleChooseCell: UITableViewCell {
//    static let reuseIdentifier = "\(MultipleChooseCell.self)"
//
//    @IBOutlet weak var checkImageView: UIImageView!
//    @IBOutlet weak var titleLabel: UILabel!
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
//    
//    func layoutCell(option: MutlipleChooseOption) {
//        titleLabel.text = option.item
//        checkImageView.isHidden = !option.isSelected
//    }
//}
