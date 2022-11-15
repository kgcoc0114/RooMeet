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
    var gender: Int?
}

protocol PostBasicCellDelegate: AnyObject {
    func showRegionPickerView(cell: PostBasicCell)
    func passData(cell: PostBasicCell, data: PostBasicData)
}

class PostBasicCell: UICollectionViewCell {
    static let reuseIdentifier = "\(PostBasicCell.self)"
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

    @IBOutlet weak var titleTextField: RMBaseTextField!
    @IBOutlet weak var addressTextField: RMBaseTextField!

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

    @IBOutlet weak var datePickerTextField: RMBaseTextField! {
        didSet {
            let toolbar = UIToolbar()
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(datePickerDone))
            ]
            toolbar.sizeToFit()

            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .inline
            datePicker.tintColor = .hexColor(hex: "#437471")

            datePickerTextField.placeholder = "YYYY/MM/DD"
            datePickerTextField.inputView = datePicker

            datePicker.addTarget(self, action: #selector(movinDateChanged(_:)), for: .valueChanged)
        }
    }

    @IBOutlet weak var leasePickerView: NumberPickerView!
    @IBOutlet weak var genderSegmentControl: UISegmentedControl! {
        didSet {
            postBasicData.gender = genderSegmentControl.selectedSegmentIndex
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

        parlorCountView.delegate = self
        roomCountView.delegate = self
        leasePickerView.delegate = self
    }

    @objc private func movinDateChanged(_ sender: UIDatePicker) {
        postBasicData.movinDate = sender.date
        datePickerTextField.text = RMDateFormatter.shared.dateString(date: sender.date)
        delegate?.passData(cell: self, data: postBasicData)
    }

    @objc private func datePickerDone() {
        self.endEditing(true)
    }
}

extension PostBasicCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == regionSelectView {
            delegate?.showRegionPickerView(cell: self)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        postBasicData.title = titleTextField.text
        postBasicData.address = addressTextField.text
        delegate?.passData(cell: self, data: postBasicData)
    }
}

extension PostBasicCell: NumberPickerViewDelegate {
    func didPickLease(picker: NumberPickerView, lease: Int, unit: String) {
        var leaseMon = lease * 12

        postBasicData.leaseMonth = unit == "年" ? leaseMon : lease
        print(postBasicData
        )
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
