//
//  IntroCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit

protocol IntroCellDelegate: AnyObject {
    func showRegionPickerView(cell: IntroCell)
    func passData(cell: IntroCell, data: User)
    func didClickImageView(_ cell: IntroCell)
}

class IntroCell: UICollectionViewCell {
    static let identifier = "IntroCell"

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped(tapGestureRecognizer:)))
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var regionTextField: RMBaseTextField!
    @IBOutlet weak var birthdayTextField: RMBaseTextField! {
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

            birthdayTextField.placeholder = "YYYY/MM/DD"
            birthdayTextField.inputView = datePicker

            datePicker.addTarget(self, action: #selector(onDateValueChange(_:)), for: .valueChanged)
        }
    }

    @IBOutlet weak var nameTextField: RMBaseTextField!

    @IBOutlet weak var imageButton: UIButton!

    @IBOutlet weak var introTextView: UITextView!
    
    var county: String? {
        didSet {
            if
                let county = county,
                let town = town {
                regionTextField.text = "\(county)\(town)"
            }
            user?.favoriteCounty = county
        }
    }

    var town: String? {
        didSet {
            if
                let county = county,
                let town = town {
                regionTextField.text = "\(county)\(town)"
            }
            user?.favoriteTown = town
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
        regionTextField.delegate = self
        introTextView.delegate = self
        imageButton.setTitle("Edit", for: .normal)
    }

    override func layoutSubviews() {
        imageView.layer.cornerRadius = imageButton.bounds.height / 2
    }

    func configureCell(edit: Bool = true, data: User) {
        self.user = data
        if edit {
            guard let user = self.user else {
                return
            }

            nameTextField.text = user.name

            if let birthday = user.birthday {
                birthdayTextField.text = RMDateFormatter.shared.dateString(date: birthday)
            } else {
                birthdayTextField.text = ""
            }

            if let profilePhoto = user.profilePhoto {
                imageView.setImage(urlString: profilePhoto)
            } else {
                imageView.image = UIImage.asset(.profile_user)
            }

            if let favoriteCounty = user.favoriteCounty,
                let favoriteTown = user.favoriteTown {
                regionTextField.text = "\(favoriteCounty)\(favoriteTown)"
            }

            if let introduction = user.introduction {
                introTextView.text = "\(introduction)"
            }

            guard let rules = user.rules else {
                return
            }

            self.rules = rules
        }
    }

    @objc func textFieldDone(_ sender: UIBarButtonItem) {
        self.endEditing(true)
        user?.gender = segmentedControl.selectedSegmentIndex
        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }

    @objc private func datePickerDone() {
        self.endEditing(true)
    }


    @objc func onDateValueChange(_ datePicker: UIDatePicker) {
        birthday = datePicker.date
        guard let birthday = birthday else {
            return
        }
        birthdayTextField.text = RMDateFormatter.shared.dateString(date: birthday)
        user?.birthday = birthday
        user?.gender = segmentedControl.selectedSegmentIndex
        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }
}

extension IntroCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == regionTextField {
            delegate?.showRegionPickerView(cell: self)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        user?.name = nameTextField.text ?? ""
        user?.gender = segmentedControl.selectedSegmentIndex

        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }
}

extension IntroCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        user?.introduction = textView.text
        print(user?.introduction, textView.text)
        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }
}
