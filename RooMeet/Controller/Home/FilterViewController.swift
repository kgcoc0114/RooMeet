//
//  FilterViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/6.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class FilterViewController: RMButtomSheetViewController {
    var minBudget: Int = 0
    var maxBudget: Int = 10000000
    var blockUserIDs: [String] = []

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Filter"
        titleLabel.font = UIFont.regularTitle()
        titleLabel.textColor = .mainDarkColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    var completion: ((Query) -> Void)?

    lazy var minBudgetTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(budgetTextFieldValueChange), for: .valueChanged)
        textField.layer.borderColor = UIColor.mainLightColor.cgColor
        textField.layer.borderWidth = 0.8
        textField.placeholder = "最少月租"
        textField.keyboardType = .numberPad
        return textField
    }()

    lazy var maxBudgetTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(budgetTextFieldValueChange), for: .valueChanged)
        textField.layer.borderColor = UIColor.mainLightColor.cgColor
        textField.layer.borderWidth = 0.8
        textField.placeholder = "最多月租"
        textField.keyboardType = .numberPad
        return textField
    }()

    lazy var applyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Filter", for: .normal)
        button.tintColor = UIColor.mainBackgroundColor
        button.backgroundColor = UIColor.mainColor
        button.addTarget(self, action: #selector(applyAction), for: .touchUpInside)
        button.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultHeight = 350
        currentContainerHeight = 350

        setupBaseView()
        setupBaseConstraints()

        configureLayout()
    }

    func configureLayout() {
        containerView.addSubview(titleLabel)
        containerView.addSubview(applyButton)
        containerView.addSubview(minBudgetTextField)
        containerView.addSubview(maxBudgetTextField)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            maxBudgetTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.35),
            minBudgetTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.35),
            maxBudgetTextField.heightAnchor.constraint(equalToConstant: 40),
            minBudgetTextField.heightAnchor.constraint(equalToConstant: 40),
            maxBudgetTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            maxBudgetTextField.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 10),
            minBudgetTextField.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -10),
            minBudgetTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            applyButton.heightAnchor.constraint(equalToConstant: 55),
            applyButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            applyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20)
        ])
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

    @objc func applyAction(_ sender: Any) {
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

        blockUserIDs.append(UserDefaults.id)

        let query = FirestoreEndpoint.room.colRef
            .whereField("roomMinPrice", isGreaterThan: minBudget)
            .whereField("roomMinPrice", isLessThan: maxBudget)
            .whereField("userID", notIn: blockUserIDs)
            .order(by: "roomMinPrice")
            .order(by: "createdTime")

        self.completion?(query)
        dismiss(animated: true)
    }
}
