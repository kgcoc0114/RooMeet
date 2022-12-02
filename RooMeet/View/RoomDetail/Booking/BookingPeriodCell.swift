//
//  BookingPeriodCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit

protocol BookingPeriodCellDelegate: AnyObject {
    func didSelectPeriod(selectedPeriod: BookingPeriod)
}

class BookingPeriodCell: UICollectionViewCell {
    static let identifier = "BookingPeriodCell"

    var selectPeriod: BookingPeriod?
    weak var delegate: BookingPeriodCellDelegate?

    lazy var periodPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()

    @IBOutlet weak var periodTextField: UITextField! {
        didSet {
            periodTextField.inputView = periodPickerView

            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            button.setBackgroundImage(UIImage(named: "Icons_24px_DropDown"), for: .normal)
            button.isUserInteractionEnabled = false

            periodTextField.rightView = button
            periodTextField.rightViewMode = .always
            periodTextField.placeholder = "選擇時段"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        periodTextField.delegate = self
    }
}

extension BookingPeriodCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == periodTextField && !textField.hasText {
            let defaultSelectedRow = 0
            periodPickerView.selectRow(defaultSelectedRow, inComponent: 0, animated: false)
            periodTextField.text = BookingPeriod.allCases[defaultSelectedRow].descrption
            selectPeriod = BookingPeriod.allCases[defaultSelectedRow]
            guard let selectPeriod = selectPeriod else {
                return
            }
            delegate?.didSelectPeriod(selectedPeriod: selectPeriod)
        }
    }

}

extension BookingPeriodCell: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        BookingPeriod.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return BookingPeriod.allCases[row].descrption
    }
}

extension BookingPeriodCell: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        periodTextField.text = BookingPeriod.allCases[row].descrption
        selectPeriod = BookingPeriod.allCases[row]
        guard let selectPeriod = selectPeriod else {
            return
        }
        delegate?.didSelectPeriod(selectedPeriod: selectPeriod)
    }
}
