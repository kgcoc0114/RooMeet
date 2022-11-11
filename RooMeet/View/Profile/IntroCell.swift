//
//  IntroCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

enum Habit {
    case `switch`
    case ps
    case sport
    case cook
    case dessert
    case climbing
}

protocol IntroCellDelegate: AnyObject {
    func showRegionPickerView(cell: IntroCell)
    func showRulePickerView(cell: IntroCell)
    func passData(cell: IntroCell, data: User)
    func didClickImageView(_ cell: IntroCell)
}

class IntroCell: UICollectionViewCell {
    static let identifier = "IntroCell"

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))

            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField! {
        didSet {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .inline

            datePicker.addTarget(self, action: #selector(onDateValueChange), for: .valueChanged)

            birthdayTextField.inputView = datePicker

            let toolbar = UIToolbar()
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(textFieldDone))
            ]
            toolbar.sizeToFit()
            birthdayTextField.inputAccessoryView = toolbar
        }
    }

    @IBOutlet weak var nameTextField: UITextField!

    @IBOutlet weak var ruleTextField: UITextField!

    @IBOutlet weak var imageButton: UIButton!

    @IBOutlet weak var introTextView: UITextView!

    var county: String? {
        didSet {
            if
                let county = county,
                let town = town {
                regionTextField.text = "\(county)\(town)"
            }
            user?.favorateCounty = county
        }
    }

    var town: String? {
        didSet {
            if
                let county = county,
                let town = town {
                regionTextField.text = "\(county)\(town)"
            }
            user?.favorateTown = town
        }
    }

    var user: User?
    var name: String?
    var email: String?
    var birthday: Date?
    var introduction: String?
    var rules: [String] = []

    var empty = false
    weak var delegate: IntroCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        nameTextField.delegate = self
        birthdayTextField.delegate = self
        ruleTextField.delegate = self
        regionTextField.delegate = self
        imageButton.setTitle("Edit", for: .normal)
    }

    func configureCell(edit: Bool = true, data: User) {
        self.user = data
        if edit {
            guard let user = self.user else {
                return
            }

            birthdayTextField.isEnabled = false
            nameTextField.text = user.name
            birthdayTextField.text = RMDateFormatter.shared.dateString(date: user.birthday)
            if user.favorateTown != nil {
                regionTextField.text = "\( user.favorateCounty)\(user.favorateTown)"
            }

            if user.introduction != nil {
                introTextView.text = "\( user.introduction)"
            }

            guard let rules = user.rules else {
                return
            }

            self.rules = rules
            print("gCurrentUser.profilePhoto = ", user.profilePhoto)
        }
    }

    @objc func textFieldDone(_ sender: UIBarButtonItem) {
        self.endEditing(true)
        delegate?.passData(cell: self, data: user!)
    }

    @objc func onDateValueChange(_ datePicker: UIDatePicker) {
        birthday = datePicker.date
        guard let birthday = birthday else {
            return
        }
        birthdayTextField.text = RMDateFormatter.shared.dateString(date: birthday)
        user?.birthday = birthday
        delegate?.passData(cell: self, data: user!)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }
}

extension IntroCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == regionTextField {
            delegate?.showRegionPickerView(cell: self)
        } else if textField == ruleTextField {
            delegate?.showRulePickerView(cell: self)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        user?.name = nameTextField.text ?? ""
        delegate?.passData(cell: self, data: user!)
    }
}
