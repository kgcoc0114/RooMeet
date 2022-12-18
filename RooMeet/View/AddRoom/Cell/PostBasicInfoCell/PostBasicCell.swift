//
//  PostBasicCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

struct PostBasicData {
    var title: String?
    var county: String?
    var town: String?
    var address: String?
    var room: Int?
    var parlor: Int?
    var leaseMonth: Int?
    var movinDate: Date?
}

protocol PostBasicCellDelegate: AnyObject {
    func showRegionPickerView(cell: PostBasicCell)
    func passData(cell: PostBasicCell, data: PostBasicData)
}

class PostBasicCell: UICollectionViewCell {
    var county: String? {
        didSet {
            postBasicData.county = county
            if let county = county,
                let town = town {
                regionSelectView.text = "\(county)\(town)"
            }
            delegate?.passData(cell: self, data: postBasicData)
        }
    }

    var town: String? {
        didSet {
            postBasicData.town = town
            if let county = county,
                let town = town {
                regionSelectView.text = "\(county)\(town)"
            }
            delegate?.passData(cell: self, data: postBasicData)
        }
    }

    private var postBasicData = PostBasicData()

    weak var delegate: PostBasicCellDelegate?
    var lastTextField: UITextField?

    @IBOutlet weak var titleTextField: RMBaseTextField! {
        didSet {
            titleTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        }
    }

    @IBOutlet weak var addressTextField: RMBaseTextField! {
        didSet {
            addressTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        }
    }

    @IBOutlet weak var regionSelectView: RMBaseTextField!

    @IBOutlet weak var parlorCountView: NumberPickerView! {
        didSet {
            postBasicData.parlor = 0
        }
    }

    @IBOutlet weak var roomCountView: NumberPickerView! {
        didSet {
            postBasicData.room = 0
        }
    }

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.minimumDate = Date()
        datePicker.tintColor = .mainColor
        datePicker.addTarget(self, action: #selector(movinDateChanged(_:)), for: .valueChanged)
        return datePicker
    }()

    @IBOutlet weak var datePickerTextField: RMBaseTextField! {
        didSet {
            datePickerTextField.placeholder = "YYYY/MM/DD (必填)"
            datePickerTextField.inputView = datePicker
        }
    }

    @IBOutlet weak var leasePickerView: NumberPickerView!
    @IBOutlet weak var regionSelectionButton: UIButton! {
        didSet {
            regionSelectionButton.titleLabel?.font = UIFont.regularText()
            regionSelectionButton.backgroundColor = .mainLightColor
            regionSelectionButton.tintColor = .mainDarkColor
            regionSelectionButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            regionSelectionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        }
    }

    private var parlor: Int = 0
    private var room: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        roomCountView.configurateLayout(placeholder: "0", type: "number", maxNumber: 5)
        parlorCountView.configurateLayout(placeholder: "0", type: "number", maxNumber: 5)
        leasePickerView.configurateLayout(placeholder: "年月", type: "lease", maxNumber: 12)

        regionSelectView.delegate = self
        titleTextField.delegate = self
        addressTextField.delegate = self
        datePickerTextField.delegate = self

        parlorCountView.delegate = self
        roomCountView.delegate = self
        leasePickerView.delegate = self
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        if sender == titleTextField {
            postBasicData.title = titleTextField.text
        } else if sender == addressTextField {
            postBasicData.address = addressTextField.text
        }

        delegate?.passData(cell: self, data: postBasicData)
    }

    func configureCell(data: PostBasicData?) {
        guard let basicData = data else {
            return
        }
        postBasicData = basicData

        titleTextField.text = postBasicData.title
        addressTextField.text = postBasicData.address

        if let county = postBasicData.county,
            let town = postBasicData.town {
            regionSelectView.text = "\(county)\(town)"
        }

        if let parlor = postBasicData.parlor {
            parlorCountView.quantityField.text = parlor == 0 ? nil : "\(parlor)"
        }

        if let room = postBasicData.room {
            roomCountView.quantityField.text = room == 0 ? nil : "\(room)"
        }

        if let movinDate = postBasicData.movinDate {
            datePickerTextField.text = RMDateFormatter.shared.dateString(date: movinDate)
        }

        if let leaseMonth = postBasicData.leaseMonth {
            if leaseMonth >= 12 {
                let year = leaseMonth / 12
                leasePickerView.quantityField.text = "\(year) 年"
            } else {
                leasePickerView.quantityField.text = leaseMonth == 0 ? nil : "\(leaseMonth) 月"
            }
        }
    }

    @objc private func movinDateChanged(_ sender: UIDatePicker) {
        postBasicData.movinDate = sender.date
        datePickerTextField.text = RMDateFormatter.shared.dateString(date: sender.date)
        delegate?.passData(cell: self, data: postBasicData)
    }

    @IBAction func regionSelectionAction(_ sender: Any) {
        if lastTextField != nil {
            lastTextField?.resignFirstResponder()
        }
        delegate?.showRegionPickerView(cell: self)
    }
}

extension PostBasicCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        lastTextField = textField
        if textField == datePickerTextField && !datePickerTextField.hasText {
            postBasicData.movinDate = datePicker.date
            datePickerTextField.text = RMDateFormatter.shared.dateString(date: datePicker.date)
            delegate?.passData(cell: self, data: postBasicData)
        }
    }
}

extension PostBasicCell: NumberPickerViewDelegate {
    func didPickLease(picker: NumberPickerView, lease: Int, unit: String) {
        let leaseMon = lease * 12
        postBasicData.leaseMonth = unit == "年" ? leaseMon : lease
        delegate?.passData(cell: self, data: postBasicData)
    }

    func didPickNumber(picker: NumberPickerView, number: Int) {
        if picker == roomCountView {
            room = number
            postBasicData.room = room
            delegate?.passData(cell: self, data: postBasicData)
        } else if picker == parlorCountView {
            parlor = number
            postBasicData.parlor = parlor
            delegate?.passData(cell: self, data: postBasicData)
        }
    }
}
