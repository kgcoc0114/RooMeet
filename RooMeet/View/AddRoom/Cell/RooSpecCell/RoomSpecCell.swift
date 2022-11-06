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
    @IBOutlet weak var typeSegmentControl: UISegmentedControl!
    var roomSpec: RoomSpec?
    var indexPath: IndexPath?
    var addColumnAction: ((RoomSpecCell) -> Void)?
    var delectColumnAction: ((RoomSpecCell) -> Void)?

    weak var delegate: RoomSpecCellDelegate?

    var currentSelected: RoomType?

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var priceTextField: RMBaseTextField! {
        didSet {
            priceTextField.keyboardType = .numberPad
            priceTextField.delegate = self
        }
    }

    @IBOutlet weak var spaceTextField: RMBaseTextField! {
        didSet {
            spaceTextField.keyboardType = .numberPad
            spaceTextField.delegate = self
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
        // Initialization code
    }

    func configureLayout(roomSpec data: RoomSpec, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.roomSpec = data
        if let roomSpec = self.roomSpec {
            peopleTextField.text = setTextFieldDisplay(data: roomSpec.people)
            priceTextField.text = setTextFieldDisplay(data: roomSpec.price)
            spaceTextField.text = setTextFieldDisplay(data: roomSpec.space)
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
        guard peopleTextField.text != nil,
              let people = peopleTextField.text,
              priceTextField.text != nil,
              let price = priceTextField.text,
              spaceTextField.text != nil,
              let space = spaceTextField.text,
              let peopleCount = Int(people),
              let price = Int(price),
              let space = Double(space) else {
            return
        }

        let roomType = RoomType.allCases[typeSegmentControl.selectedSegmentIndex].desc

        delegate?.didChangeData(self, data: RoomSpec(roomType: roomType, price: price, space: space, people: peopleCount))
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
