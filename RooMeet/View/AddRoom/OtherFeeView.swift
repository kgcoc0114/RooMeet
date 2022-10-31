//
//  OtherFeeView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

class OtherFeeView: UIView {
    var feeType: String?

    lazy private var feeLabel: UILabel = {
        let label = UILabel()
        label.text = "電費"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var twButton: UIButton = {
        let button = UIButton()
        button.setTitle("台電", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var priceLabel: UILabel = {
        let label = UILabel()
        label.text = "度/月"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var priceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "degree"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy private var sharedButton: UIButton = {
        let button = UIButton()
        button.setTitle("總費用均分", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var selfButton: UIButton = {
        let button = UIButton()
        button.setTitle("獨立電表", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle
    required init() {
//        print("maxNumber")maxNumber: Int
//        self.maxNumber = maxNumber
        super.init(frame: .zero)
        configureHierarchy()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureHierarchy()
    }
    
    private func configureHierarchy() {
//        addSubview(quantityField)
//
//        quantityField.text = "fjojo"
//        NSLayoutConstraint.activate([
//            self.widthAnchor.constraint(equalToConstant: 100),
//            self.heightAnchor.constraint(equalToConstant: 100),
////            quantityField.widthAnchor.constraint(equalTo: self.widthAnchor),
////            quantityField.heightAnchor.constraint(equalTo: self.heightAnchor),
//            quantityField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
//            quantityField.centerYAnchor.constraint(equalTo: self.centerYAnchor)
//        ])
    }


}
