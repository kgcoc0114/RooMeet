//
//  FeeDetailCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/1.
//

import UIKit

class FeeDetailCell: UICollectionViewCell {
    static let reuseIdentifier = "\(FeeDetailCell.self)"

    @IBOutlet weak var otherDescTextView: UITextView! {
        didSet {
            let toolbar = UIToolbar()
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
            ]
            toolbar.sizeToFit()
            
            self.translatesAutoresizingMaskIntoConstraints = false
            //        otherDescTextView.rightView = button
            //        otherDescTextView.rightViewMode = .always
            otherDescTextView.inputAccessoryView = toolbar
            //        otherDescTextView.
            self.completion?(otherDescTextView.text)
        }
    }
    
    var completion: ((String) -> Void)?

    @IBOutlet weak var feeDetailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        otherDescTextView.delegate = self
    }

    @objc func doneButtonAction(){
        self.resignFirstResponder()
    }
}

extension FeeDetailCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.completion?(textView.text)
    }
}
