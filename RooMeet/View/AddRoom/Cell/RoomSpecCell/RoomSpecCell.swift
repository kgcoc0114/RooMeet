//
//  RoomSpecCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

protocol RoomSpecCellDelegate: AnyObject {
    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec)
}

class RoomSpecCell: UICollectionViewCell {
    @IBOutlet var typeButtons: [UIButton]!
    static let reuseIdentifier = "\(RoomSpecCell.self)"

    @IBOutlet weak var typeSegmentControl: UISegmentedControl! {
        didSet {
            typeSegmentControl.backgroundColor = UIColor.hexColor(hex: "#E9EEEE")
            typeSegmentControl.selectedSegmentTintColor = .white
            typeSegmentControl.tintColor = RMConstants.shared.mainColor
        }
    }

    var roomSpec: RoomSpec?
    var indexPath: IndexPath?
    var addColumnAction: ((RoomSpecCell) -> Void)?
    var delectColumnAction: ((RoomSpecCell) -> Void)?

    weak var delegate: RoomSpecCellDelegate?

    var currentSelected: RoomType?

    @IBOutlet weak var cardView: UIView! {
        didSet {
            cardView.layer.cornerRadius = 20
            cardView.layer.borderColor = UIColor.hexColor(hex: "#E9EEEE").cgColor
            cardView.layer.borderWidth = 1
        }
    }

    @IBOutlet weak var addButton: UIButton! {
        didSet {
            addButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var deleteButton: UIButton! {
        didSet {
            deleteButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularSubTitle()
            titleLabel.textColor = UIColor.mainDarkColor
        }
    }
    @IBOutlet weak var priceTextField: RMBaseTextField! {
        didSet {
            priceTextField.keyboardType = .numberPad
            priceTextField.delegate = self
            priceTextField.placeholder = "月租金"
        }
    }

    @IBOutlet weak var priceImageView: UIImageView! {
        didSet {
            priceImageView.image = UIImage.asset(.dollar)
        }
    }

    @IBOutlet weak var spaceImageView: UIImageView! {
        didSet {
            spaceImageView.image = UIImage.asset(.home)
        }
    }


    @IBOutlet weak var spaceTextField: RMBaseTextField! {
        didSet {
            spaceTextField.keyboardType = .decimalPad
            spaceTextField.delegate = self
            spaceTextField.placeholder = "坪數"
        }
    }

    @IBOutlet weak var peopleTextField: RMBaseTextField! {
        didSet {
            peopleTextField.keyboardType = .numberPad
            peopleTextField.delegate = self
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureLayout(roomSpec data: RoomSpec, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.roomSpec = data
        if let roomSpec = self.roomSpec {
            priceTextField.text = setTextFieldDisplay(data: roomSpec.price)
            spaceTextField.text = setTextFieldDisplay(data: roomSpec.space)
            if let dataRoomType = data.roomType,
                let roomType = RoomType(rawValue: dataRoomType),
                let roomTypeIndex = RoomType.allCases.firstIndex(of: roomType) {
                typeSegmentControl.selectedSegmentIndex = roomTypeIndex
            }
        }

        if indexPath.item == 0 {
            setButtonStatus(deleteIsHidden: true, addIsHidden: false)
        } else {
            setButtonStatus(deleteIsHidden: false, addIsHidden: false)
        }
    }

    private func setButtonStatus(deleteIsHidden: Bool, addIsHidden: Bool) {
        deleteButton.isHidden = deleteIsHidden
        addButton.isHidden = addIsHidden
    }

    private func setTextFieldDisplay<T>(data: T?) -> String {
        guard let value = data else {
            return ""
        }
        return String(describing: value)
    }

    private func passData() {
        guard priceTextField.text != nil,
            let price = priceTextField.text,
            spaceTextField.text != nil,
            let space = spaceTextField.text,
            let price = Int(price),
            let space = Double(space) else {
            return
        }

        let roomType = RoomType.allCases[typeSegmentControl.selectedSegmentIndex].rawValue

        delegate?.didChangeData(self, data: RoomSpec(roomType: roomType, price: price, space: space))
    }

    @IBAction func addRoomSpecColumn(_ sender: Any) {
        self.addColumnAction?(self)
    }

    @IBAction func delectRoomSpecColumn(_ sender: Any) {
        self.delectColumnAction?(self)
    }
}

extension RoomSpecCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        passData()
    }
}
