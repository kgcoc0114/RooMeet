//
//  RoomSpecCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

protocol RoomSpecCellDelegate: AnyObject {
    func didChangeData(_ cell: RoomSpecCell, data: RoomSpec)
    func addSpec(_ cell: RoomSpecCell)
    func deleteSpec(_ cell: RoomSpecCell)
}

class RoomSpecCell: UICollectionViewCell {
    @IBOutlet var typeButtons: [UIButton]!

    @IBOutlet weak var typeSegmentControl: UISegmentedControl! {
        didSet {
            typeSegmentControl.backgroundColor = UIColor.hexColor(hex: "#E9EEEE")
            typeSegmentControl.selectedSegmentTintColor = .white
            typeSegmentControl.tintColor = .mainDarkColor
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

    @IBOutlet weak var segmentControl: RMSegmentedControl! {
        didSet {
            segmentControl.items = RoomType.allCases.map { $0.rawValue }
            segmentControl.borderColor = UIColor.mainLightColor
            segmentControl.selectedLabelColor = UIColor.mainDarkColor
            segmentControl.unselectedLabelColor = UIColor.mainColor
            segmentControl.backgroundColor = .white
            segmentControl.thumbColor = UIColor.mainLightColor
            segmentControl.selectedIndex = 0
            segmentControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
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
            priceTextField.placeholder = "月租金(必填)"
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
            spaceTextField.placeholder = "坪數(必填)"
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

    override func prepareForReuse() {
        super.prepareForReuse()
        segmentControl.selectedIndex = 0
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
                segmentControl.selectedIndex = roomTypeIndex
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

        let roomType = RoomType.allCases[segmentControl.selectedIndex].rawValue
        delegate?.didChangeData(self, data: RoomSpec(roomType: roomType, price: price, space: space))
    }

    @objc func segmentValueChanged(_ sender: RMSegmentedControl) {
        passData()
    }

    @IBAction func addRoomSpecColumn(_ sender: Any) {
        delegate?.addSpec(self)
    }

    @IBAction func delectRoomSpecColumn(_ sender: Any) {
        delegate?.deleteSpec(self)
    }
}

extension RoomSpecCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        passData()
    }
}

//extension RoomSpecCell: PostCell {
//    func configure(container: RMCellContainer) {
//        guard
//            let container = (container as? PostDataContainer),
//            let indexPath = container.indexPath else { return }
//
//        self.indexPath = indexPath
//        self.roomSpec = container.postScenario.roomSpecList[indexPath.item]
//
//        if let roomSpec = self.roomSpec {
//            priceTextField.text = setTextFieldDisplay(data: roomSpec.price)
//            spaceTextField.text = setTextFieldDisplay(data: roomSpec.space)
//            if let dataRoomType = roomSpec.roomType,
//               let roomType = RoomType(rawValue: dataRoomType) {
//                segmentControl.selectedIndex = roomType.index
//            }
//        }
//        setButtonStatus(deleteIsHidden: indexPath.item == 0, addIsHidden: false)
//    }
//}
