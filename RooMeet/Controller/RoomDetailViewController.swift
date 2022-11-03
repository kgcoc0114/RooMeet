//
//  RoomDetailViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import UIKit

class RoomDetailViewController: UIViewController {
    var room: Room?
    
    @IBOutlet weak var testLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if room != nil {
            testLabel.text = room?.roomID
        }
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
