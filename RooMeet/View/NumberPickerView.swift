//
//  NumberPickerView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class NumberPickerView: UIView {
    private var maxNumber: Int = 5
    lazy private var quantityField: RMBaseTextField = {
        let field = RMBaseTextField()
        field.returnKeyType = .default

        let numberPicker = UIPickerView()
        numberPicker.dataSource = self
        numberPicker.delegate = self
        field.inputView = numberPicker

        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        button.setBackgroundImage(
            UIImage(named: "Icons_24px_DropDown"),
            for: .normal
        )
        button.isUserInteractionEnabled = false

        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(textFieldDone))
        ]
        toolbar.sizeToFit()

        field.translatesAutoresizingMaskIntoConstraints = false
        field.rightView = button
        field.rightViewMode = .always
        field.inputAccessoryView = toolbar
        field.placeholder = "Number"
        field.textColor = UIColor.gray
        return field
    }()

    // MARK: - Lifecycle
    required init(maxNumber: Int) {
        print("maxNumber")
        self.maxNumber = maxNumber
        super.init(frame: .zero)
        configureHierarchy()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureHierarchy()
    }

    // MARK: - Configurations

    private func configureHierarchy() {
        addSubview(quantityField)

        NSLayoutConstraint.activate([
            quantityField.widthAnchor.constraint(equalTo: self.widthAnchor),
            quantityField.heightAnchor.constraint(equalTo: self.heightAnchor),
            quantityField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            quantityField.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    func configurateLayout(placeholder: String) {
        quantityField.placeholder = placeholder
    }

    @objc private func textFieldDone() {
        quantityField.endEditing(true)
    }
}

extension NumberPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return maxNumber
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        quantityField.text = "\(row + 1)"
    }
}
