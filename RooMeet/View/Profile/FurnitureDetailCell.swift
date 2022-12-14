//
//  FurnitureDetailCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import UIKit

protocol FurnitureDetailCellDelegate: AnyObject {
    func passData(_ cell: FurnitureDetailCell, data: Furniture)
    func showMeasure(_ cell: FurnitureDetailCell, type: String)
    func didClickImageView(_ cell: FurnitureDetailCell)
}

class FurnitureDetailCell: UITableViewCell {
    @IBOutlet weak var titleTextField: RMBaseTextField! {
        didSet {
            titleTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        }
    }

    @IBOutlet weak var lengthTextField: RMBaseTextField! {
        didSet {
            lengthTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            lengthTextField.keyboardType = .numberPad
        }
    }

    @IBOutlet weak var specBackgroundView: UIView! {
        didSet {
            specBackgroundView.layer.borderWidth = 0.8
            specBackgroundView.layer.borderColor = UIColor.mainLightColor.cgColor
            specBackgroundView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    @IBOutlet weak var photoImageView: UIImageView! {
        didSet {
            photoImageView.isUserInteractionEnabled = true
            photoImageView.contentMode = .scaleAspectFill
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped(tapGestureRecognizer:)))
            photoImageView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.isUserInteractionEnabled = true
            photoImageView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBOutlet weak var widthTextField: RMBaseTextField! {
        didSet {
            widthTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            widthTextField.keyboardType = .numberPad
        }
    }

    @IBOutlet weak var heightTextField: RMBaseTextField! {
        didSet {
            heightTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            heightTextField.keyboardType = .numberPad
        }
    }

    @IBOutlet weak var lengthButton: UIButton! {
        didSet {
            lengthButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var widthButton: UIButton! {
        didSet {
            widthButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var heightButton: UIButton! {
        didSet {
            heightButton.setTitle("", for: .normal)
        }
    }
    weak var delegate: FurnitureDetailCellDelegate?

    var funiture: Furniture?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        lengthTextField.delegate = self
        heightTextField.delegate = self
        widthTextField.delegate = self
    }

    func configure(scenario: FurnitureScenario) {
        self.funiture = scenario.furniture

        titleTextField.text = funiture?.title
        lengthTextField.text = scenario.lengthString
        heightTextField.text = scenario.heightString
        widthTextField.text = scenario.widthString
        photoImageView.loadImage(funiture?.imageURL, placeHolder: UIImage.asset(.add))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleTextField.text = nil
        lengthTextField.text = nil
        widthTextField.text = nil
        heightTextField.text = nil
        photoImageView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func tapLengthAction(_ sender: Any) {
        delegate?.showMeasure(self, type: "length")
    }

    @IBAction func tapWidthAction(_ sender: Any) {
        delegate?.showMeasure(self, type: "width")
    }

    @IBAction func tapHeightAction(_ sender: Any) {
        delegate?.showMeasure(self, type: "height")
    }
}

// MARK: - Target Action
@objc private extension FurnitureDetailCell {
    func textFieldChanged(_ sender: UITextField) {
        switch sender {
        case titleTextField:
            if let content = sender.text {
                funiture?.title = content
            }
        case lengthTextField:
            if let content = sender.text {
                funiture?.length = transToInt(input: content)
            }
        case widthTextField:
            if let content = sender.text {
                funiture?.width = transToInt(input: content)
            }
        case heightTextField:
            if let content = sender.text {
                funiture?.height = transToInt(input: content)
            }
        default:
            print("")
        }

        guard let funiture = funiture else {
            return
        }
        delegate?.passData(self, data: funiture)
    }

    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.didClickImageView(self)
    }
}

extension FurnitureDetailCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if textField.hasText,
            let text = textField.text {
            textField.text = text + "cm"
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard var text = textField.text else {
            return
        }

        text = text.replace(target: "cm", withString: "")
        print(text)
        textField.text = text
    }
}

extension FurnitureDetailCell {
    func transToInt(input: String) -> Int? {
        if let outputNumber = Int(input.replace(target: "cm", withString: "")) {
            return outputNumber
        } else {
            return nil
        }
    }
}


extension String {
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(
            of: target,
            with: withString,
            options: NSString.CompareOptions.literal,
            range: nil)
    }
}
