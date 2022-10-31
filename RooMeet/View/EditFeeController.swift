//
//  EditFeeController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

struct Fee {
    var type: String?
    var paid: Bool = false
    var price: Double?
    var unit: String?
    var paidType: String?
}

class EditFeeController: UIViewController {

    @IBOutlet weak var sperate1Button: MyButton!
    @IBOutlet weak var share1Button: MyButton!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var twBillButton: MyButton!
    
//    var isSelected: Bool

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tapSperateButton(_ sender: Any) {
        sperate1Button.isSelected = !sperate1Button.isSelected
        share1Button.isSelected = !sperate1Button.isSelected
        print("=========")
        print("sperate1Button.isSelected", sperate1Button.isSelected)
        print("share1Button.isSelected", share1Button.isSelected)
    }

    @IBAction func tapShareButton(_ sender: Any) {
        share1Button.isSelected = !share1Button.isSelected
        sperate1Button.isSelected = !share1Button.isSelected
        print("=========")
        print("sperate1Button.isSelected", sperate1Button.isSelected)
        print("share1Button.isSelected", share1Button.isSelected)
    }

    @IBAction func tapTwBillButton(_ sender: Any) {
        twBillButton.isSelected = true
    }
}

class MyButton : UIButton {

    override var isSelected: Bool {
        didSet {
            print("changed from \(oldValue) to \(isSelected)")
        }
    }
}
