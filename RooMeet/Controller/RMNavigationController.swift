//
//  RMNavigationController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/13.
//

import UIKit

class RMNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationBar.backgroundColor = .hexColor(hex: "#264054")
        self.navigationBar.tintColor = .hexColor(hex: "#264054")

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
