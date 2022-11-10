//
//  TmpViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import UIKit

class TmpViewController: UIViewController, BookingViewDelegate {
    func didSendRequest(date: DateComponents, selectPeriod: BookingPeriod) {
        print(#function)
    }

    @IBOutlet weak var tmpView: UIView!
    @IBOutlet weak var test123: BookingView!

//    var dates: [DateComponents]?


    override func viewDidLoad() {
        super.viewDidLoad()
        test123.delegate = self
        // Do any additional setup after loading the view.
    }
    

//    func dodo() {
//        dates = Date().getDaysInWeek(days: 1)
//        dates?.forEach({ date in
//            let dayView = UIView()
//            dayView.frame = CGRect(x: 0, y: 0, width: 50, height: 70)
//            dayView.translatesAutoresizingMaskIntoConstraints = false
//            dayView.backgroundColor = .red
//
//            view.addSubview(dayView)
//        })
//    }

}
