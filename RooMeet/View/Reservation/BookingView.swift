//
//  BookingView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import UIKit



protocol BookingViewDelegate: AnyObject {
    func didSendRequest(date: DateComponents, selectPeriod: BookingPeriod)
}

class BookingView: UIView, NibOwnerLoadable {
    var selectDate: DateComponents?
    var selectPeriod: BookingPeriod?
    var selectView: DateView?

    lazy var dates = Date().getDaysInWeek(days: 7)

    var delegate: BookingViewDelegate?

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @IBOutlet weak var stackView: UIStackView! {
        didSet {
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
//            stackView.spacing = 10
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
        }
    }

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var periodTextField: UITextField! {
        didSet {
            let pickerView = UIPickerView()
            pickerView.dataSource = self
            pickerView.delegate = self
            periodTextField.inputView = pickerView

            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            button.setBackgroundImage(UIImage(named: "Icons_24px_DropDown"), for: .normal)
            button.isUserInteractionEnabled = false

            periodTextField.rightView = button
            periodTextField.rightViewMode = .always
        }
    }

    override class func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }

    private func customInit() {
        backgroundColor = UIColor.black
        loadNibContent()
        configureLayout()
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 100),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: stackView.heightAnchor)
        ])

        dataLabel.text = "\(dates[0].date)"
        requestButton.backgroundColor = .yellow
        requestButton.setTitle("發起預約", for: .normal)

        for xxx in 1...6 {
            let dateView = DateView()
            dateView.isUserInteractionEnabled = true

            let click = UITapGestureRecognizer(target: self, action: #selector(show))

            dateView.addGestureRecognizer(click)

            let dayLabel = UILabel()
            let weekdayLabel = UILabel()
            weekdayLabel.font = UIFont.systemFont(ofSize: 20, weight: .light)
            dayLabel.font = UIFont.systemFont(ofSize: 30, weight: .semibold)

            dateView.date = dates[xxx]
            weekdayLabel.text =  "\(dates[xxx].weekday!)"
            dayLabel.text = "\(dates[xxx].day!)"
            dayLabel.translatesAutoresizingMaskIntoConstraints = false
            weekdayLabel.translatesAutoresizingMaskIntoConstraints = false
            dateView.translatesAutoresizingMaskIntoConstraints = false
            dateView.addSubview(dayLabel)
            dateView.addSubview(weekdayLabel)
            stackView.addArrangedSubview(dateView)

            NSLayoutConstraint.activate([
                dateView.widthAnchor.constraint(equalToConstant: 80),
                dateView.heightAnchor.constraint(equalToConstant: 100),
                dayLabel.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
                weekdayLabel.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
                dayLabel.topAnchor.constraint(equalTo: dateView.topAnchor),
                weekdayLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor)
            ])
        }
    }

    @objc func show(_ sender: UITapGestureRecognizer) {
        guard let dateView = sender.view as? DateView else {
            return
        }
        // 第一次選擇
//        if selectView == nil {
//            selectDate = dateView.date
//            selectView = dateView
//            dateView.isSelected = true
//
//        } else {
//            // 取消此次選擇
//            if dateView == selectView {
//                selectView?.isSelected = false
//                selectDate = nil
//                selectView = nil
//            } else {
//                selectView?.isSelected = false
//                dateView.isSelected = true
//                selectDate = dateView.date
//                selectView = dateView
//            }
//        }
        print(selectDate)
    }


    @IBAction func sendReservation(_ sender: Any) {
        print("11111", selectDate, selectPeriod)
        guard let selectDate = selectDate,
              let selectPeriod = selectPeriod else {
            print("須選時間與地點")
            return
        }

        delegate?.didSendRequest(date: selectDate, selectPeriod: selectPeriod)
    }

    
}

extension BookingView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        BookingPeriod.allCases.count + 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "選擇時段"
        } else {
            return BookingPeriod.allCases[row - 1].descrption
        }
    }
}

extension BookingView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(BookingPeriod.allCases[row - 1].descrption)
        periodTextField.text = BookingPeriod.allCases[row - 1].descrption
        selectPeriod = BookingPeriod.allCases[row - 1]
    }
}

//class DateView: UIView {
//    var date: DateComponents?
//    var isSelected: Bool = false {
//        didSet {
//            self.backgroundColor = isSelected == false ? .white : .yellow
//        }
//    }
//}
