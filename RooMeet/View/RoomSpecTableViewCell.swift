//
//  RoomSpecTableViewCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

protocol RoomSpecTableViewCellDelegate: AnyObject {
    func didChangeData(_ cell: RoomSpecTableViewCell, data: RoomSpec)
}

class RoomSpecTableViewCell: UITableViewCell {
    static let reuseIdentifier = "\(RoomSpecTableViewCell.self)"
    var roomSpec: RoomSpec?
    
    @IBOutlet weak var roomTypeStackView: UIStackView!
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
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var addButton: UIButton!

    var addColumnAction: ((RoomSpecTableViewCell) -> Void)?
    var delectColumnAction: ((RoomSpecTableViewCell) -> Void)?

    weak var delegate: RoomSpecTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureLayout(deleteIsHidden: Bool, addIsHidden: Bool) {
        deleteButton.isHidden = deleteIsHidden
        addButton.isHidden = addIsHidden
        
    }

    func configureLayout(deleteIsHidden: Bool, addIsHidden: Bool, data: RoomSpec) {
        deleteButton.isHidden = deleteIsHidden
        addButton.isHidden = addIsHidden
        self.roomSpec = data
        peopleTextField.text = roomSpec?.people == nil ? "" : String(describing: roomSpec!.people!)
        priceTextField.text = roomSpec!.price == nil ? "" : String(describing: roomSpec!.price!)
        spaceTextField.text = roomSpec?.space == nil ? "" : String(describing: roomSpec!.space!)
        
    }
    
    @IBAction func addRoomSpecColumn(_ sender: Any) {
        self.addColumnAction?(self)
    }

    @IBAction func delectRoomSpecColumn(_ sender: Any) {
        self.delectColumnAction?(self)
    }

    func passDate() {
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
}

extension RoomSpecTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        passDate()
    }
}


