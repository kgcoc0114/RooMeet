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
                    ) { _ in
                        print("insert message success")
                    }
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
            insertMessage(senderID: sender, receiverID: receiver, status: status, reservation: reservation) { _ in
                print("insert message success")
            }
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

    func resetLastMessage(chatRoomID: String) {
        let query = FirestoreEndpoint.chatRoom.colRef
            .document(chatRoomID)
            .collection("Message")
            .order(by: "createdTime", descending: true)
            .limit(to: 1)

        query.getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if error != nil {
                print("ERROR: - fetch data error")
            }

            if let querySnapshot = querySnapshot,
               let document = querySnapshot.documents.first {
                do {
                    if let message = try? document.data(as: Message.self) {
                        self.updateLastMessage(chatRoomID: chatRoomID, message: message)
                    }
                } catch {
                    print("ERROR: - \(error.localizedDescription)")
                }
            }
        }
    }

    func updateLastMessage(chatRoomID: String, message: Message) {
        var content = message.content
        let chatRoomRef = FirestoreEndpoint.chatRoom.colRef.document(chatRoomID)
        if message.messageType == 3 {
            let acceptedStatus = AcceptedStatus.init(rawValue: message.content)
            content = acceptedStatus?.content ?? ""
        }

        let lastMessage = LastMessage(
            id: message.id,
            content: content,
            createdTime: message.createdTime
        )

        chatRoomRef.updateData([
            "lastMessage": lastMessage.toDict,
            "lastUpdated": lastMessage.createdTime
        ])
    }

    func insertMessage(
        senderID: String,
        receiverID: String,
        status: AcceptedStatus,
        reservation: Reservation,
        completion: @escaping ((String?) -> Void)
    ) {
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

            completion(chatRoom.id)
        }
    }

    // 更新已被回覆過的預約訊息狀態
    func updateCurrentMessageStatus(status: AcceptedStatus, currentUser: User, otherUser: User, message: Message) {
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

    func replyReservation(reservation: Reservation, status: AcceptedStatus, requestUserID: String, completion: @escaping ((Error?) -> Void)) {
        var reservation = reservation
        guard
            let receiver = reservation.receiver,
            let sender = reservation.sender else {
            return
        }

        let oriStatus = AcceptedStatus.init(rawValue: reservation.acceptedStatus ?? "waiting")

        reservation.acceptedStatus = status.description
        reservation.modifiedTime = Timestamp()

        updateReservationStatus(status: status, reservation: reservation)

        // 刪除發起者的 reservationID
        if status == .cancel {
            deleteUserReservation(userID: sender, reservationID: reservation.id)
            deleteUserReservation(userID: receiver, reservationID: reservation.id)
        }

        // 更新 message / last message
        if sender == UserDefaults.id && status == .cancel && oriStatus == .waiting {
            guard
                let sender = reservation.sender,
                let receiver = reservation.receiver
            else {
                return
            }

            FirebaseService.shared.getChatRoomByUserID(userA: sender, userB: receiver) { [weak self] chatRoom in
                guard let self = self else { return }
                self.deleteRequestReservationMessage(chatRoomID: chatRoom.id, reservationID: reservation.id, status: .cancel)
                completion(nil)
            }
        } else {
            insertMessage(
                senderID: sender,
                receiverID: receiver,
                status: status,
                reservation: reservation
            ) { [weak self] chatRoomID in
                guard
                    let self = self,
                    let chatRoomID = chatRoomID else {
                    return
                }
                self.deleteRequestReservationMessage(chatRoomID: chatRoomID, reservationID: reservation.id, status: .answer)
                completion(nil)
            }
        }
    }

    func deleteRequestReservationMessage(chatRoomID: String, reservationID: String, status: AcceptedStatus) {
        let query = FirestoreEndpoint.chatRoom.colRef
            .document(chatRoomID)
            .collection("Message")
            .whereField("content", isEqualTo: "waiting")
            .whereField("messageType", isEqualTo: 3)

        query.getDocuments { [weak self] snapshot, error in
            guard
                let snapshot = snapshot,
                let self = self else {
                return
            }

            for document in snapshot.documents {
                do {
                    let data = try document.data(as: Message.self)
                    if let reservation = data.reservation,
                        reservation.id == reservationID {
                        if status == .cancel {
                            document.reference.delete()
                            self.resetLastMessage(chatRoomID: chatRoomID)
                        } else {
                            document.reference.updateData(["content": status.description])
                        }
                        break
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func deleteExpiredReservations() {
        var expiredRsvns: [String] = []
        let group = DispatchGroup()
        group.enter()
        let currentTimestamp = Timestamp()
        let senderQuery = FirestoreEndpoint.reservation.colRef
            .whereField("isDeleted", isEqualTo: false)
            .whereField("requestTime", isLessThan: currentTimestamp)
            .whereField("sender", isEqualTo: UserDefaults.id)
        batchDeleteReservation(query: senderQuery) { rsvns in
            expiredRsvns += rsvns
            group.leave()
        }

        group.enter()
        let receiverQuery = FirestoreEndpoint.reservation.colRef
            .whereField("isDeleted", isEqualTo: false)
            .whereField("requestTime", isLessThan: currentTimestamp)
            .whereField("receiver", isEqualTo: UserDefaults.id)
        batchDeleteReservation(query: receiverQuery) { rsvns in
            expiredRsvns += rsvns
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            FirebaseService.shared.deleteUserRsvnData(expiredRsvns: expiredRsvns)
        }
    }

    private func batchDeleteReservation(query: Query, completion: @escaping (([String]) -> Void)) {
        let batch = Firestore.firestore().batch()
        var expiredRsvn: [String] = []
        query.getDocuments { querySnapshot, error in
            if let querySnapshot = querySnapshot {
                querySnapshot.documents.forEach { document in
                    batch.updateData(["isDeleted": true], forDocument: document.reference)
                    expiredRsvn.append(document.documentID)
                }

                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error writing batch \(error)")
                    } else {
                        print("Batch write succeeded.")
                    }
                }
                completion(expiredRsvn)
            }
        }
    }
}
