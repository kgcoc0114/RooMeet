//
//  RoomDetailViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import UIKit

class RoomDetailViewController: UIViewController {
    
    var room: Room?
    var chatMembers: [ChatMember]?

    @IBOutlet weak var testLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if room != nil {
            testLabel.text = room?.roomID
        }
    }


}
