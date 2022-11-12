//
//  OUReservationCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class OUReservationCell: MessageBaseCell {
    static let reuseIdentifier = "\(OUReservationCell.self)"

    @IBOutlet weak var denyButton: UIButton! {
        didSet {
            denyButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            denyButton.backgroundColor = .hexColor(hex: RMColor.mainDark.hex)
            denyButton.tintColor = .white
            denyButton.titleLabel!.font =  UIFont.regular(size: 15)
        }
    }

    @IBOutlet weak var agreeButton: UIButton! {
        didSet {
            agreeButton.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            agreeButton.backgroundColor = .hexColor(hex: RMColor.mainBlue.hex)
            agreeButton.tintColor = .white
            agreeButton.titleLabel!.font =  UIFont.regular(size: 15)
        }
    }

    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.font = UIFont.regular(size: RMConstants.shared.reservationStatusFontSize)
        }
    }

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var cellView: UIView! {
        didSet {
            cellView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            cellView.backgroundColor = MsgType.other.backgroundColor
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleToFill
            avatarView.layer.cornerRadius = RMConstants.shared.avaterImageWidth / 2
        }
    }

    var message: Message?
    var otherUser: ChatMember?
    var currentUser: ChatMember?
    var sendByMe = true

    override func awakeFromNib() {
        super.awakeFromNib()
        denyButton.isHidden = true
        agreeButton.isHidden = true
        denyButton.addTarget(self, action: #selector(deny), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(accept), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: 5),
            timeLabel.bottomAnchor.constraint(equalTo: cellView.bottomAnchor),
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
            let currentUser = currentUser,
            let reservation = message.reservation else {
            return
        }

        avatarView.setImage(urlString: otherUser.profilePhoto)
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
                    statusLabel.isHidden = true
                    denyButton.isHidden = true
                    agreeButton.isHidden = true
                    
                } else {
                    titleLabel.text = "\(otherUser.name) 已發來預約"
                    let dateString = RMDateFormatter.shared.dateString(date: reservation.requestTime!.dateValue())
                    statusLabel.text = "\(dateString)\n\(reservation.period!)"
                    denyButton.isHidden = false
                    agreeButton.isHidden = false
                }
            } else if reservation.acceptedStatus == "accept" {
                titleLabel.text = "預約已完成"
                let dateString = RMDateFormatter.shared.dateString(date: reservation.requestTime!.dateValue())
                statusLabel.text = "\(dateString)\n\(reservation.period!)"
                statusLabel.isHidden = false
                denyButton.isHidden = true
                agreeButton.isHidden = true
            } else if reservation.acceptedStatus == "cancel" {
                titleLabel.text = "預約已取消"
                let dateString = RMDateFormatter.shared.dateString(date: reservation.requestTime!.dateValue())
                statusLabel.text = "\(dateString)\n\(reservation.period!)"
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

    // 更新已被回覆過的預約訊息狀態
    func updateCurrentMessageStatus(status: AcceptedStatus) {
        guard
            let message = message,
            let currentUser = currentUser,
            let otherUser = otherUser
        else {
            return
        }

        FirebaseService.shared.getChatRoomByUserID(userA: currentUser.id, userB: otherUser.id) { [weak self] chatroom in
            guard let `self` = self else { return }
            self.updateMessage(
                chatRoomID: chatroom.id,
                message: message,
                status: status
            )
        }
    }

    // 更新已被回覆過的預約訊息狀態
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
