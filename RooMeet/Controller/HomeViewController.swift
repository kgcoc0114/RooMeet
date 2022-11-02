//
//  HomeViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/30.
//

import UIKit

class HomeViewController: UIViewController {
    lazy var  topSelectionView: NumberPickerView = {
        let view = NumberPickerView(maxNumber: 5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var  buttonSelectionView: NumberPickerView = {
        let view = NumberPickerView(maxNumber: 5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    @IBOutlet weak var addPostButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(topSelectionView)
        view.addSubview(buttonSelectionView)
//        topSelectionView.backgroundColor = .blue
//        buttonSelectionView.backgroundColor = .red
        NSLayoutConstraint.activate([
            topSelectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonSelectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topSelectionView.widthAnchor.constraint(equalToConstant: 200),
            topSelectionView.heightAnchor.constraint(equalToConstant: 100),
            buttonSelectionView.widthAnchor.constraint(equalToConstant: 200),
            buttonSelectionView.heightAnchor.constraint(equalToConstant: 100),
            buttonSelectionView.topAnchor.constraint(equalTo: topSelectionView.bottomAnchor, constant: -200)
        ])
}
    
    
    @IBAction func addRoomPost(_ sender: Any) {
        let postVC = PostViewController()
//        postVC.initVC(pageType: .rule, selectedOptions: ["Cats OK", "Couples OK"])
//        postVC.completion = { selectedItem in
//            print(selectedItem)
//
//        }
        navigationController?.pushViewController(postVC, animated: true)
    }
}
