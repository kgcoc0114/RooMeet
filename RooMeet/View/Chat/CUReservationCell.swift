//
//  CUReservationCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class CUReservationCell: UITableViewCell {
    static let reuseIdentifier = "\(CUReservationCell.self)"

    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    var message: Message?
    var chatroomID: String?
    var otherUser: ChatMember?
    var currentUser: ChatMember?
    var sendByMe = true

    override func awakeFromNib() {
        super.awakeFromNib()
        denyButton.isHidden = true
        agreeButton.isHidden = true
        denyButton.addTarget(self, action: #selector(deny), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureLayout() {
        guard let message = message,
              let otherUser = otherUser,
              let currentUser = currentUser,
              let reservation = message.reservation else {
            return
        }

        statusLabel.text = reservation.acceptedStatus
        if message.content == "answer" {
            titleLabel.text = "預約已回覆"
            statusLabel.isHidden = true
            denyButton.isHidden = true
            agreeButton.isHidden = true
        } else {
            if reservation.acceptedStatus == "waiting" {
                if reservation.sender == gCurrentUser.id {
                    titleLabel.text = "已發起預約，等候回覆"
                    denyButton.isHidden = true
                    agreeButton.isHidden = true
                } else {
                    titleLabel.text = "\(otherUser.name)已發來預約\n \(reservation.requestTime)\n\(reservation.period)"
                    denyButton.isHidden = false
                    agreeButton.isHidden = false
                }
            } else if reservation.acceptedStatus == "accept" {
                titleLabel.text = "預約已完成"
                denyButton.isHidden = true
                agreeButton.isHidden = true
            } else if reservation.acceptedStatus == "cancel" {
                titleLabel.text = "預約已取消"
                denyButton.isHidden = true
                agreeButton.isHidden = true
            }
        }
    }

    @objc func deny() {
        guard
            let message = message,
//            let otherUser = otherUser,
//            let currentUser = currentUser,
            let reservation = message.reservation else {
            return
        }

        updateCurrentMessageStatus(status: .answer)

        ReservationService.shared.upsertReservationData(status: .cancel, reservation: reservation)
    }

    @objc func accept() {
        guard
            let message = message,
//            let otherUser = otherUser,
//            let currentUser = currentUser,
            let reservation = message.reservation else {
            return
        }

        updateCurrentMessageStatus(status: .answer)

        ReservationService.shared.upsertReservationData(status: .accept, reservation: reservation)
    }

    func updateCurrentMessageStatus(status: AcceptedStatus) {
        guard
            let message = message,
            let currentUser = currentUser,
            let otherUser = otherUser
        else {
            return
        }

        FirebaseService.shared.getChatRoomByUserID(
            userA: currentUser.id, userB: otherUser.id) { [weak self] chatroom in
                guard let `self` = self else { return }
                self.updateMessage(
                    chatRoomID: chatroom.id,
                    message: message,
                    status: status
                )
            }
    }

    func updateMessage(chatRoomID: String, message: Message, status: AcceptedStatus) {
        let messageRef = Firestore.firestore()
            .collection("ChatRoom")
            .document(chatRoomID)
            .collection("Message")
            .document(message.id)

        messageRef.updateData([
            "content": status.description
        ])
    }
}
