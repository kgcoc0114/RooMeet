//
//  OUReservationCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/10.
//

import UIKit
import FirebaseFirestore

class OUReservationCell: MessageBaseCell {
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

    var otherUser: ChatMember?
    var currentUser: ChatMember?

    override func awakeFromNib() {
        super.awakeFromNib()
        msgType = .other
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

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
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
        answerReservationMessage(status: .answer)

        ReservationService.shared.upsertReservationData(status: .cancel, reservation: reservation)
    }

    @objc func accept() {
        guard
            let message = message,
            let reservation = message.reservation else {
            return
        }

        answerReservationMessage(status: .answer)

        ReservationService.shared.upsertReservationData(status: .accept, reservation: reservation)
    }

    func answerReservationMessage(status: AcceptedStatus) {
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

extension OUReservationCell: ChatCell {
    func configure(for data: ChatData) {
        self.message = data.message
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

        avatarView.loadImage(otherUser.profilePhoto, placeHolder: UIImage.asset(.roomeet))

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
            titleLabel.text = "\(otherUser.name) " + (expiredInd == true ? "已發來預約" : "預約已過期")
            denyButton.isHidden = !expiredInd
            agreeButton.isHidden = !expiredInd
        default:
            break
        }

        assignDatetime(messageDate: data.message.createdTime.dateValue())
    }
}
