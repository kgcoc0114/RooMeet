//
//  RMTextField.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class RMBaseTextField: UITextField {

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addUnderLine()
        addToolbar()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addUnderLine()
        addToolbar()
    }

    private func addUnderLine() {
        let underline = UIView()

        underline.translatesAutoresizingMaskIntoConstraints = false

        addSubview(underline)

        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 50),
            leadingAnchor.constraint(equalTo: underline.leadingAnchor),
            trailingAnchor.constraint(equalTo: underline.trailingAnchor),
            bottomAnchor.constraint(equalTo: underline.bottomAnchor),
            underline.heightAnchor.constraint(equalToConstant: 1)
        ])

        underline.backgroundColor = .hexColor(hex: "#F1F5F9")
        self.font = UIFont.regular(size: 15)
    }

    private func addToolbar() {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(textFieldDone))
        ]
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.borderWidth = 0
    }

    @objc private func textFieldDone() {
        self.endEditing(true)
    }
}
