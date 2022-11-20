//
//  CUReservationCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class CUReservationCell: MessageBaseCell {
    static let reuseIdentifier = "\(CUReservationCell.self)"
    var msgType: MsgType = .currentUser

    @IBOutlet weak var messageView: UIView! {
        didSet {
            messageView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            messageView.backgroundColor = msgType.backgroundColor
        }
    }

    @IBOutlet weak var reservationIcon: UIImageView!

    @IBOutlet weak var stackView: UIStackView! {
        didSet {
            stackView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

    @IBOutlet weak var denyButton: UIButton! {
        didSet {
            denyButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            denyButton.backgroundColor = UIColor.mainDarkColor
            denyButton.tintColor = .white
            denyButton.titleLabel!.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var agreeButton: UIButton! {
        didSet {
            agreeButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            agreeButton.backgroundColor = UIColor.mainColor
            agreeButton.tintColor = .white
            agreeButton.titleLabel!.font = UIFont.regularSubTitle()
        }
    }

    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.font = UIFont.regularText()
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularSubTitle()
        }
    }

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

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -5),
            timeLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func configureLayout() {
        guard
            let message = message,
            let otherUser = otherUser,
            let reservation = message.reservation,
            let requestTime = reservation.requestTime,
            let requestPeriod = reservation.period
        else {
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
                statusLabel.isHidden = true
                if reservation.sender == UserDefaults.id {
                    titleLabel.text = "已發起預約，等候回覆"
                    denyButton.isHidden = true
                    agreeButton.isHidden = true
                } else {
                    titleLabel.text = "\(otherUser.name)已發來預約\n \(requestTime)\n\(requestPeriod)"
                    denyButton.isHidden = false
                    agreeButton.isHidden = false
                }
            } else if reservation.acceptedStatus == "accept" {
                titleLabel.text = "預約已完成"
                let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
                statusLabel.text = "\(dateString)\n\(requestPeriod)"
                statusLabel.isHidden = false
                denyButton.isHidden = true
                agreeButton.isHidden = true
            } else if reservation.acceptedStatus == "cancel" {
                titleLabel.text = "預約已取消"
                let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
                statusLabel.text = "\(dateString)\n\(requestPeriod)"
                statusLabel.isHidden = false
                denyButton.isHidden = true
                agreeButton.isHidden = true
            }
        }

        assignDatetime(messageDate: message.createdTime.dateValue())
    }

    @objc func deny() {
        guard
            let message = message,
            let reservation = message.reservation else {
            return
        }

        updateCurrentMessageStatus(status: .answer)

        ReservationService.shared.upsertReservationData(status: .cancel, reservation: reservation)
    }

    @objc func accept() {
        guard
            let message = message,
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
