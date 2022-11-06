//
//  FilterViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class FilterViewController: UIViewController {
    var minBudget: Int = 0
    var maxBudget: Int = 10000000

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "Filter"
            titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    var completion: ((Query) -> (Void))?

    @IBOutlet weak var minBudgetTextField: UITextField!

    @IBOutlet weak var maxBudgetTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc private func budgetTextFieldValueChange(_ sender: UITextField) {
        switch sender {
        case minBudgetTextField:
            if
                minBudgetTextField.hasText,
                let minBudgetText = minBudgetTextField.text {
                minBudget = Int(minBudgetText) ?? 0
            }
        default:
            if
                maxBudgetTextField.hasText,
                let maxBudgetText = maxBudgetTextField.text {
                maxBudget = Int(maxBudgetText) ?? 0
            }
        }
    }

    @IBAction func cancelAction(_ sender: Any) {
        maxBudgetTextField.text = ""
        minBudgetTextField.text = ""
        dismiss(animated: true)
    }

    @IBAction func applyAction(_ sender: Any) {
        if
            minBudgetTextField.hasText,
            let minBudgetText = minBudgetTextField.text {
            minBudget = Int(minBudgetText) ?? 0
        }
        if
            maxBudgetTextField.hasText,
            let maxBudgetText = maxBudgetTextField.text {
            maxBudget = Int(maxBudgetText) ?? 0
        }
        let query = FirestoreEndpoint.room.colRef
            .whereField("roomMinPrice", isGreaterThan: minBudget)
            .whereField("roomMinPrice", isLessThan: maxBudget)
            .order(by: "roomMinPrice")
            .order(by: "createdTime")

        self.completion?(query)
        dismiss(animated: true)
    }
}
