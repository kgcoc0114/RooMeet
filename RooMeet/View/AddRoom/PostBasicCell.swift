//
//  PostBasicCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class PostBasicCell: UICollectionViewCell {
    static let reuseIdentifier = "\(PostBasicCell.self)"

    var county: String? {
        didSet {
            if county != nil && town != nil {
                regionSelectView.text = "\(county!)\(town!)"
            }
        }
    }
    var town: String?  {
        didSet {
            if county != nil && town != nil {
                regionSelectView.text = "\(county!)\(town!)"
            }
        }
    }
    weak var delegate: PostBasicCellDelegate?
    @IBOutlet weak var regionSelectView: UITextField!
    
    @IBOutlet weak var parlorCountView: NumberPickerView!
    @IBOutlet weak var roomCountView: NumberPickerView!
    override func awakeFromNib() {
        super.awakeFromNib()
        roomCountView.configurateLayout(placeholder: "Room")
        parlorCountView.configurateLayout(placeholder: "Parlor")
        regionSelectView.delegate = self
        
    }
    
    // TODO: Region selectView

}

extension PostBasicCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print(textField)
        delegate?.showRegionPickerView(cell: self)
        //        regionSelectView.resignFirstResponder()
        //
        //        let vc = RegionPickerViewController()
        //        vc.completion = { [weak self] county, town in
        //            guard let `self` = self else { return }
        //            self.county = county
        //            self.town = town
        //        }
        //        self.present(vc, animate: true)
    }
    
}

//extension PostBasicCell: UITextFieldDelegate {
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        regionSelectView.resignFirstResponder()
//
//        let vc = RegionPickerViewController()
//        vc.completion = { [weak self] county, town in
//            guard let `self` = self else { return }
//            self.county = county
//            self.town = town
//        }
//        self.present(vc, animate: true)
//    }
    
//}

protocol PostBasicCellDelegate: AnyObject {
    func showRegionPickerView(cell: PostBasicCell)
}
