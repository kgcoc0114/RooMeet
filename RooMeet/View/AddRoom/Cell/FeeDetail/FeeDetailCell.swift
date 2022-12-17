//
//  FeeDetailCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/1.
//

import UIKit

class FeeDetailCell: UICollectionViewCell {

    @IBOutlet weak var otherDescTextView: UITextView! {
        didSet {
            let toolbar = UIToolbar()
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
            ]
            toolbar.sizeToFit()

            otherDescTextView.translatesAutoresizingMaskIntoConstraints = false
            otherDescTextView.backgroundColor = .systemGray6
            otherDescTextView.text = ""
            otherDescTextView.inputAccessoryView = toolbar
            self.completion?(otherDescTextView.text)
        }
    }

    var completion: ((String) -> Void)?

    @IBOutlet weak var feeDetailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        otherDescTextView.delegate = self
    }

    override func layoutSubviews() {
        otherDescTextView.layer.cornerRadius = otherDescTextView.bounds.height * 0.1
    }

    @objc func doneButtonAction() {
        otherDescTextView.resignFirstResponder()
    }
}

extension FeeDetailCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.completion?(textView.text)
    }
}

extension FeeDetailCell: PostCell {
    func configure(container: RMCellContainer) {}
}
