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
    static let reuseIdentifier = "\(RoomSpecCell.self)"
    var roomSpec: RoomSpec?
    var indexPath: IndexPath?
    var addColumnAction: ((RoomSpecCell) -> Void)?
    var delectColumnAction: ((RoomSpecCell) -> Void)?

    weak var delegate: RoomSpecCellDelegate?

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

        peopleTextField.text = setTextFieldDisplay(data: roomSpec!.people)
        priceTextField.text = setTextFieldDisplay(data: roomSpec!.price)
        spaceTextField.text = setTextFieldDisplay(data: roomSpec!.space)

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
              priceTextField.text != nil,
              spaceTextField.text != nil,
              let peopleCount = Int(peopleTextField.text!),
              let price = Int(priceTextField.text!),
              let space = Double(spaceTextField.text!) else {
            return
        }
        let roomType = "Single"
        let amenities = ["Bed", "TV"]
        delegate?.didChangeData(self, data: RoomSpec(roomType: [1], price: price, space: space, people: peopleCount, amenities: amenities))
        
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
