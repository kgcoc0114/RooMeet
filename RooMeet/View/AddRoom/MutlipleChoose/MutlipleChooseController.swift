//
//  MutlipleChooseController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/31.
//

import UIKit

enum Rules: String, CaseIterable {
    case noSmoking = "No Smoking"
    case noPets = "No Pets"
    case noDrinking = "No Drinking"
    case catsOk = "Cats OK"
    case dogsOk = "Dogs OK"
    case otherPetsOk = "Other Pets OK"
    case couplesOk = "Couples OK"
}

//enum Rules: String, CaseIterable {
//    case pets = "寵物"
//    case cooking = "做飯"
//    case elevator = "電梯"
//    case gender = "租客性別"
//    case bathroom = "衛浴"
//
//    var items: [String] {
//        switch self {
//        case .pets:
//            return ["不可寵", "可養貓", "可養狗", "可議"]
//        case .cooking:
//            return ["可做飯", "不可做飯"]
//        case .elevator:
//            return ["有電梯", "無電梯"]
//        case .gender:
//            return ["男女不限", "限男", "限女"]
//        case .bathroom:
//            return ["獨立衛浴", "公用衛浴"]
//        }
//    }
//}

enum Amenities: String, CaseIterable {
    case refrigerator = "冰箱"
    case waterHeater = "熱水器"
    case wifi = "網路"
    case balcony = "陽台"
    case washer = "洗衣機"
    case doorman = "管理員"
    case tv = "電視"
}

//roomFeatures  =
//enum Features: String, CaseIterable {
//    case noSmoking = "No Smoking"
//    case noPets = "No Pets"
//    case noDrinking = "No Drinking"
//    case catsOk = "Cats OK"
//    case dogsOk = "Dogs OK"
//    case otherPetsOk = "Other Pets OK"
//    case couplesOk = "Couples OK"
//}


enum MutlipleChooseType {
    case rule
    case amenities

    var desc: String {
        switch self {
        case .rule:
            return "其他條件"
        case .amenities:
            return "設備"
        }
    }
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

    @IBOutlet weak var confirmButton: UIButton! {
        didSet {
            confirmButton.setTitle("確認", for: .normal)
            confirmButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            confirmButton.backgroundColor = RMConstants.shared.mainColor
            confirmButton.tintColor = RMConstants.shared.mainLightColor
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        }
    }

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            UINib(nibName: OptionCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OptionCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        if let pageType = pageType{
            titleLabel.text = pageType.desc
        }
    }

    func setup(pageType: MutlipleChooseType, selectedOptions: [String] = []) {
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
        let selectedItem = options
            .filter({ option in
                option.isSelected == true
            })
            .map { option in
            option.item
        }
        self.completion?(selectedItem)
        dismiss(animated: true)
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
