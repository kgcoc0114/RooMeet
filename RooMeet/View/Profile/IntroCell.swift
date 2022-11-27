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

    @IBOutlet weak var imageButton: UIButton! {
        didSet {
            imageButton.setImage(UIImage.asset(.refresh), for: .normal)
        }
    }

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped(tapGestureRecognizer:)))
            imageView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBOutlet weak var genderSegmentedControl: RMSegmentedControl! {
        didSet {
            genderSegmentedControl.items = Gender.allCases.map { $0.rawValue }
            genderSegmentedControl.borderColor = UIColor.mainLightColor
            genderSegmentedControl.selectedLabelColor = UIColor.mainDarkColor
            genderSegmentedControl.unselectedLabelColor = UIColor.mainColor
            genderSegmentedControl.backgroundColor = .white
            genderSegmentedControl.thumbColor = UIColor.mainLightColor
            genderSegmentedControl.selectedIndex = 0
            genderSegmentedControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        }
    }

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.textColor = .mainDarkColor
            nameLabel.font = .regularSubTitle()
        }
    }

    @IBOutlet weak var genderLabel: UILabel! {
        didSet {
            genderLabel.textColor = .mainDarkColor
            genderLabel.font = .regularSubTitle()
        }
    }

    @IBOutlet weak var birthLabel: UILabel! {
        didSet {
            birthLabel.textColor = .mainDarkColor
            birthLabel.font = .regularSubTitle()
        }
    }

    @IBOutlet weak var areaLabel: UILabel! {
        didSet {
            areaLabel.textColor = .mainDarkColor
            areaLabel.font = .regularSubTitle()
        }
    }

    @IBOutlet weak var introLabel: UILabel! {
        didSet {
            introLabel.textColor = .mainDarkColor
            introLabel.font = .regularSubTitle()
        }
    }

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
            datePicker.tintColor = .mainColor

            birthdayTextField.placeholder = "YYYY/MM/DD"
            birthdayTextField.inputView = datePicker

            datePicker.addTarget(self, action: #selector(onDateValueChange(_:)), for: .valueChanged)
        }
    }

    @IBOutlet weak var nameTextField: RMBaseTextField! {
        didSet {
            nameTextField.addTarget(self, action: #selector(onTextFieldValueChange), for: .valueChanged)
        }
    }

    @IBOutlet weak var introTextView: UITextView! {
        didSet {
            introTextView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            introTextView.backgroundColor = .mainLightColor
            introTextView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            introTextView.text = ""
        }
    }

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
    }

    override func layoutSubviews() {
        imageButton.layer.cornerRadius = imageButton.bounds.width / 2
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

            if let gender = user.gender {
                genderSegmentedControl.selectedIndex = gender
            }

            if let profilePhoto = user.profilePhoto {
                imageView.setImage(urlString: profilePhoto)
            } else {
                imageView.image = UIImage.asset(.roomeet)
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
        } else {
            introTextView.text = ""
        }
    }

    @objc func textFieldDone(_ sender: UIBarButtonItem) {
        self.endEditing(true)

        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }

    @objc private func datePickerDone() {
        self.endEditing(true)
    }

    @objc func onTextFieldValueChange(_ sender: UITextField) {
        guard var user = user else { return }
        user.name = nameTextField.text
        delegate?.passData(cell: self, data: user)
    }

    @objc func onDateValueChange(_ datePicker: UIDatePicker) {
        birthday = datePicker.date
        guard let birthday = birthday else {
            return
        }
        birthdayTextField.text = RMDateFormatter.shared.dateString(date: birthday)
        user?.birthday = birthday
        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }

    @objc func segmentValueChanged(_ sender: RMSegmentedControl) {
        user?.gender = genderSegmentedControl.selectedIndex

        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
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

        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }
}

extension IntroCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        user?.introduction = textView.text

        guard let user = user else { return }
        delegate?.passData(cell: self, data: user)
    }
}
