//
//  MutlipleChooseController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

//enum Rules: String, CaseIterable {
//
//    case noSmoking = "No Smoking"
//    case noPets = "No Pets"
//    case noSmoking = "No Smoking"
//    case noSmoking = "No Smoking"
//    case noSmoking = "No Smoking"
//    case noSmoking = "No Smoking"
//}

enum Rules: String, CaseIterable {
    case noSmoking = "No Smoking"
    case noPets = "No Pets"
    case noDrinking = "No Drinking"
    case catsOk = "Cats OK"
    case dogsOk = "Dogs OK"
    case otherPetsOk = "Other Pets OK"
    case couplesOk = "Couples OK"
}

enum Amenities: String, CaseIterable {
    case noSmoking = "No Smoking"
    case noPets = "No Pets"
    case noDrinking = "No Drinking"
}

enum MutlipleChooseType {
    case rule
    case amenities
}

struct MutlipleChooseOption {
    let item: String
    var isSelected: Bool
}

class MutlipleChooseController: UIViewController {
    lazy var rules: [MutlipleChooseOption] = {
        let items = Rules.allCases
        let rulesItems = items.map { rule in
            MutlipleChooseOption(item: rule.rawValue, isSelected: false)
        }
        return rulesItems
    }()
    
    lazy var amenities: [MutlipleChooseOption] = {
        let items = Amenities.allCases
        let rulesItems = items.map { rule in
            MutlipleChooseOption(item: rule.rawValue, isSelected: false)
        }
        return rulesItems
    }()

    var options: [MutlipleChooseOption] = []

    var pageType: MutlipleChooseType? {
        didSet {
            switch pageType {
            case .rule:
                options = rules
            case .amenities:
                options = amenities
            case .none:
                options = []
            }
        }
    }

    var completion: (([String]) -> Void)?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: OptionCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OptionCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    func initVC(pageType: MutlipleChooseType, selectedOptions: [String] = []) {
        self.pageType = pageType

        if !selectedOptions.isEmpty {
            genOptions(selectedOptions)
        }
    }
    
    private func genOptions(_ selectedOptions: [String]) {
        switch pageType {
        case .rule:
            options = options.map({ option in
                var tmpOption = option
                tmpOption.isSelected = selectedOptions.contains(option.item)
                return tmpOption
            })
        case .amenities:
            options = options.map({ option in
                var tmpOption = option
                tmpOption.isSelected = selectedOptions.contains(option.item)
                return tmpOption
            })
        case .none:
            options = []
        }
    }
    @IBAction func confirmAction(_ sender: Any) {
//        self.completion?(options.filter({ option in
//            option.isSelected = true
//        }))
        let selectedItem = options.filter({ option in
            option.isSelected == true
        }).map { option in
            option.item
        }
        self.completion?(selectedItem)
        dismiss(animated: true)
//        navigationController?.popViewController(animated: true)
    }
}

extension MutlipleChooseController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OptionCell.reuseIdentifier, for: indexPath) as? OptionCell else {
            fatalError("OptionCell Error")
        }
        let option = options[indexPath.item]
        cell.layoutCell(option: option)
        return cell
    }
}

extension MutlipleChooseController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OptionCell else {
            fatalError("MultipleChooseCell Error")
        }
        options[indexPath.item].isSelected = !options[indexPath.item].isSelected
        cell.checkImageView.isHidden = !options[indexPath.item].isSelected
    }
}
