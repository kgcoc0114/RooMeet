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
    var msgType: MsgType = .other

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

    @IBOutlet weak var cellView: UIView! {
        didSet {
            cellView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
            cellView.backgroundColor = msgType.backgroundColor
        }
    }

    @IBOutlet weak var avatarView: UIImageView! {
        didSet {
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.contentMode = .scaleAspectFill
            avatarView.layer.cornerRadius = RMConstants.shared.avatarImageWidth / 2
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
    }

    override func layoutSubviews() {
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
            let reservation = message.reservation else {
            return
        }

        if let profilePhoto = otherUser.profilePhoto {
            avatarView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
        } else {
            avatarView.image = UIImage.asset(.roomeet)
        }

        statusLabel.text = reservation.acceptedStatus

        if message.content == "answer" {
            titleLabel.text = "預約已回覆"
            statusLabel.isHidden = true
            denyButton.isHidden = true
            agreeButton.isHidden = true
        } else {
            guard
                let reservationPeriod = reservation.period,
                let requestTime = reservation.requestTime else {
                return
            }

            if reservation.acceptedStatus == "waiting" {
                if reservation.sender == UserDefaults.standard.string(forKey: UserDefaults.id) {
                    titleLabel.text = "已發起預約，等候回覆"
                    statusLabel.isHidden = true
                    denyButton.isHidden = true
                    agreeButton.isHidden = true
                } else {
                    titleLabel.text = "\(otherUser.name) 已發來預約"
                    let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
                    statusLabel.text = "\(dateString)\n\(reservationPeriod)"
                    statusLabel.isHidden = false
                    denyButton.isHidden = false
                    agreeButton.isHidden = false
                }
            } else if reservation.acceptedStatus == "accept" {
                titleLabel.text = "預約已完成"
                let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
                statusLabel.text = "\(dateString)\n\(reservationPeriod)"
                statusLabel.isHidden = false
                denyButton.isHidden = true
                agreeButton.isHidden = true
            } else if reservation.acceptedStatus == "cancel" {
                titleLabel.text = "預約已取消"
                let dateString = RMDateFormatter.shared.dateString(date: requestTime.dateValue())
                statusLabel.text = "\(dateString)\n\(reservationPeriod)"
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
