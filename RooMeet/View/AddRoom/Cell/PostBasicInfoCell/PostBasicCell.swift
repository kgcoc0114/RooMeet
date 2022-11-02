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
    var lease: Double?
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
            if county != nil && town != nil {
                regionSelectView.text = "\(county!)\(town!)"
            }
            delegate?.passData(cell: self, data: postBasicData)
        }
    }

    var town: String?  {
        didSet {
            postBasicData.town = town
            if county != nil && town != nil {
                regionSelectView.text = "\(county!)\(town!)"
            }
            delegate?.passData(cell: self, data: postBasicData)
        }
    }
    private var postBasicData = PostBasicData()

    weak var delegate: PostBasicCellDelegate?
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var movinDatePicker: UIDatePicker! {
        didSet {
            postBasicData.movinDate = movinDatePicker.date
        }
    }
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var regionSelectView: UITextField!
    @IBOutlet weak var leaseTextField: UITextField!
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
    private var parlor: Int = 0
    private var room: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        roomCountView.configurateLayout(placeholder: "Room")
        parlorCountView.configurateLayout(placeholder: "Parlor")
        regionSelectView.delegate = self
        titleTextField.delegate = self
        genderTextField.delegate = self
        leaseTextField.delegate = self
        addressTextField.delegate = self
        parlorCountView.delegate = self
        roomCountView.delegate = self
        movinDatePicker.addTarget(self, action: #selector(movinDateChanged), for: .valueChanged)
    }

    @objc private func movinDateChanged() {
        postBasicData.movinDate = movinDatePicker.date
        delegate?.passData(cell: self, data: postBasicData)
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
        postBasicData.gender = Int(genderTextField.text!)

        if leaseTextField.hasText {
            postBasicData.lease = Double(leaseTextField.text!)
        }

        delegate?.passData(cell: self, data: postBasicData)
    }
    
    func tecc(_ textField: UITextField) {
        print(textField)
        delegate?.showRegionPickerView(cell: self)
    }
}

extension PostBasicCell: NumberPickerViewDelegate {
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

