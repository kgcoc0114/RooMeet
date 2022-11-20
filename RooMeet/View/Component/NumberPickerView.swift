//
//  NumberPickerView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit
protocol NumberPickerViewDelegate: AnyObject {
    func didPickNumber(picker: NumberPickerView, number: Int)
    func didPickLease(picker: NumberPickerView, lease: Int, unit: String)
}

class NumberPickerView: UIView {
    var maxNumber: Int = 5
    var timeUnit = ["月", "年"]
    var pickerType: String = "number"
    var leaseTimePicked: String = "1"
    var leaseUnitPicked: String = "月"

    weak var delegate: NumberPickerViewDelegate?

    lazy var quantityField: RMBaseTextField = {
        let field = RMBaseTextField()
        field.returnKeyType = .default
        field.font = UIFont.regular(size: 15)

        let numberPicker = UIPickerView()
        numberPicker.dataSource = self
        numberPicker.delegate = self
        field.inputView = numberPicker

        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
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
        field.textColor = UIColor.darkGray
        return field
    }()

    // MARK: - Lifecycle
    required init(maxNumber: Int, type: String = "number") {
        self.maxNumber = maxNumber
        super.init(frame: .zero)
        configureHierarchy(type: "number", maxNumber: maxNumber)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Configurations

    private func configureHierarchy(type: String, maxNumber: Int = 5) {
        self.pickerType = type
        self.maxNumber = maxNumber

        addSubview(quantityField)

        NSLayoutConstraint.activate([
            quantityField.widthAnchor.constraint(equalTo: self.widthAnchor),
            quantityField.heightAnchor.constraint(equalTo: self.heightAnchor),
            quantityField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            quantityField.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    func configurateLayout(placeholder: String, type: String, maxNumber: Int = 5) {
        configureHierarchy(type: type, maxNumber: maxNumber)
        quantityField.placeholder = placeholder
    }

    @objc private func textFieldDone() {
        quantityField.endEditing(true)
    }
}

extension NumberPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerType == "number" ? 1 : 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return maxNumber
        } else {
            return timeUnit.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return pickerType == "number" ? "\(row)" : "\(row + 1)"
        } else {
            return timeUnit[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(row)
        if pickerType == "number" {
            quantityField.text = "\(row)"
            delegate?.didPickNumber(picker: self, number: row)
        } else {
            if component == 0 {
                leaseTimePicked = "\(row + 1)"
            } else {
                leaseUnitPicked = timeUnit[row]
            }
            if !leaseTimePicked.isEmpty && !leaseUnitPicked.isEmpty {
                quantityField.text = "\(leaseTimePicked) \(leaseUnitPicked)"
                delegate?.didPickLease(picker: self, lease: Int(leaseTimePicked)!, unit: leaseUnitPicked)
            }
        }
    }
}
