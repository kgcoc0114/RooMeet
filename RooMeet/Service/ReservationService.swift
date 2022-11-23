//
//  ReservationService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/9.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ReservationService {
    static let shared = ReservationService()

    func upsertReservationData(
        status: AcceptedStatus,
        requestTime: Date? = nil,
        period: String? = nil,
        room: Room? = nil,
        senderID: String? = nil,
        receiverID: String? = nil,
        reservation: Reservation? = nil
    ) {
        switch status {
        case .waiting:
            guard
                let senderID = senderID,
                let receiverID = receiverID,
                let room = room,
                let requestTime = requestTime,
                let period = period,
                let roomID = room.roomID else {
                return
            }

            insertReservation(
                senderID: senderID,
                receiverID: receiverID,
                roomID: roomID,
                status: .waiting,
                requestTime: requestTime,
                period: period
            ) { [weak self] reservation, error in
                guard let self = self else { return }
                if error != nil {
                    print("ERROR: insertReservation")
                    return
                }

                if let reservation = reservation {
                    // sender user reservation array
                    self.addUserReservation(userID: senderID, reservationID: reservation.id)

                    // receiver user reservation array
                    self.addUserReservation(userID: receiverID, reservationID: reservation.id)

                    self.insertMessage(
                        senderID: senderID,
                        receiverID: receiverID,
                        status: .waiting,
                        reservation: reservation
                    )
                }
            }
        case .cancel, .accept:
            // 你發起 我取消
            guard
                var reservation = reservation,
                let receiver = reservation.receiver,
                let sender = reservation.sender else {
                return
            }

            reservation.acceptedStatus = status.description
            reservation.modifiedTime = Timestamp()

            updateReservationStatus(status: status, reservation: reservation)

            // 刪除發起者的 reservationID
            if status == .cancel {
                deleteUserReservation(userID: sender, reservationID: reservation.id)

                deleteUserReservation(userID: receiver, reservationID: reservation.id)
            }

            // 更新 message / last message
            insertMessage(senderID: sender, receiverID: receiver, status: status, reservation: reservation)
        case .answer:
            break
        }
    }

    func addUserReservation(userID: String, reservationID: String) {
        let userQuery = FirestoreEndpoint.user.colRef.document(userID)

        userQuery.updateData([
            "reservations": FieldValue.arrayUnion([reservationID])
        ])
    }

    func deleteUserReservation(userID: String, reservationID: String) {
        let userQuery = FirestoreEndpoint.user.colRef.document(userID)

        userQuery.getDocument { document, _ in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    var reservations = user.reservations
                    if let index = reservations.firstIndex(of: reservationID) {
                        reservations.remove(at: index)
                        userQuery.updateData([
                            "reservations": reservations
                        ])
                    }
                } catch {
                    print("Error")
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func insertMessage(
        senderID: String,
        receiverID: String,
        status: AcceptedStatus,
        reservation: Reservation
    ) {
        print("senderID", senderID)
        print("receiverID", receiverID)
        FirebaseService.shared.getChatRoomByUserID(userA: senderID, userB: receiverID) { chatRoom in
            let messageRef = FirestoreEndpoint.chatRoom.colRef
                .document(chatRoom.id)
                .collection("Message")
                .document()

            let message = Message(
                id: messageRef.documentID,
                messageType: MessageType.reservation.rawValue,
                sendBy: UserDefaults.id,
                content: status.description,
                createdTime: Timestamp(),
                reservation: reservation
            )

            do {
                try messageRef.setData(from: message)
            } catch let error {
                print("Error writing Message to Firestore: \(error)")
            }

            let chatRoomRef = FirestoreEndpoint.chatRoom.colRef.document(chatRoom.id)

            let lastMessage = LastMessage(
                id: messageRef.documentID,
                content: status.content,
                createdTime: message.createdTime
            )

            chatRoomRef.updateData([
                "lastMessage": lastMessage.toDict,
                "lastUpdated": lastMessage.createdTime
            ])
        }
    }


    func insertReservation(
        senderID: String,
        receiverID: String,
        roomID: String,
        status: AcceptedStatus,
        requestTime: Date,
        period: String,
        completion: @escaping ((Reservation?, Error?) -> Void)
    ) {
        let reservation = Reservation(
            id: roomID,
            roomID: roomID,
            requestTime: Timestamp(date: requestTime),
            period: period,
            sender: senderID,
            receiver: receiverID,
            acceptedStatus: status.description,
            createdTime: Timestamp()
        )

        try? FirestoreEndpoint.reservation.colRef.document(roomID).setData(from: reservation)
        completion(reservation, nil)
    }

    func updateReservationStatus(
        status: AcceptedStatus,
        reservation: Reservation
    ) {
        let reservationRef = FirestoreEndpoint.reservation.colRef.document(reservation.id)

        reservationRef.updateData([
            "acceptedStatus": status.description,
            "modifiedTime": Timestamp()
        ])
    }
}
