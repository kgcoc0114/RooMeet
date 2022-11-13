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

    @IBOutlet weak var periodTextField: UITextField! {
        didSet {
            let pickerView = UIPickerView()
            pickerView.dataSource = self
            pickerView.delegate = self
            periodTextField.inputView = pickerView

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
        delegate?.didSelectPeriod(selectedPeriod: selectPeriod!)
    }
}
