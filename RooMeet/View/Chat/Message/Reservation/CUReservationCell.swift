//
//  CUReservationCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseFirestore

class CUReservationCell: MessageBaseCell {
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

    var chatroomID: String?
    var otherUser: ChatMember?
    var currentUser: ChatMember?

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

        FIRChatRoomService.shared.getChatRoomByMembers(members: [currentUser.id, otherUser.id]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatroom):
                self.updateMessage(
                    chatRoomID: chatroom.id,
                    message: message,
                    status: status
                )
            case .failure(let error):
                debugPrint("FirebaseService getChatRoomByMembers", error.localizedDescription)
            }
        }
    }

    func updateMessage(chatRoomID: String, message: Message, status: AcceptedStatus) {
        let messageRef = FirestoreEndpoint.chatRoom.colRef
            .document(chatRoomID)
            .collection("Message")
            .document(message.id)

        messageRef.updateData([
            "content": status.description
        ])
    }
}

extension CUReservationCell: ChatCell {
    func configure(for data: ChatData) {
        let message = data.message
        self.currentUser = data.currentUser
        self.otherUser = data.otherUser

        guard
            let otherUser = data.otherUser,
            let reservation = data.message.reservation,
            let requestTime = reservation.requestTime,
            let requestPeriod = reservation.period,
            let acceptedStatus = AcceptedStatus(rawValue: data.message.content)
        else {
            return
        }

        titleLabel.text = acceptedStatus.content
        let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
        statusLabel.text = "\(dateString)\n\(requestPeriod)"
        statusLabel.isHidden = false
        denyButton.isHidden = true
        agreeButton.isHidden = true

        switch acceptedStatus {
        case .waiting:
            let currentDate = Timestamp()
            let expiredInd = requestTime.seconds >= currentDate.seconds

            if reservation.sender == UserDefaults.id {
                titleLabel.text = "已發起預約，等候回覆" + (expiredInd == true ? "" : " - 已過期")
            } else {
                titleLabel.text = "\(otherUser.name) " + (expiredInd == true ? "已發來預約" : "預約已過期")
                denyButton.isHidden = !expiredInd
                agreeButton.isHidden = !expiredInd
            }
        default:
            break
        }

        assignDatetime(messageDate: message.createdTime.dateValue())
    }
}
