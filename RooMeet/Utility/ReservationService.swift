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
    let firebaseService = FirebaseService.shared

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
                    debugPrint("ERROR: insertReservation")
                    return
                }

                if let reservation = reservation {
                    self.addUserReservation(userID: senderID, reservationID: reservation.id)

                    self.addUserReservation(userID: receiverID, reservationID: reservation.id)

                    self.insertMessage(
                        senderID: senderID,
                        receiverID: receiverID,
                        status: .waiting,
                        reservation: reservation
                    ) { _ in
                        debugPrint("insert message success")
                    }
                }
            }
        case .cancel, .accept:
            guard
                var reservation = reservation,
                let receiver = reservation.receiver,
                let sender = reservation.sender else {
                return
            }

            reservation.acceptedStatus = status.description
            reservation.modifiedTime = Timestamp()

            updateReservationStatus(status: status, reservation: reservation)

            if status == .cancel {
                deleteUserReservation(userID: sender, reservationID: reservation.id)
                deleteUserReservation(userID: receiver, reservationID: reservation.id)
            }

            insertMessage(senderID: sender, receiverID: receiver, status: status, reservation: reservation) { _ in
                debugPrint("insert message success")
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

        firebaseService.getDocument(userQuery) { (user: User?) in
            guard let user = user else {
                return
            }

            var reservations = user.reservations
            if let index = reservations.firstIndex(of: reservationID) {
                reservations.remove(at: index)
                userQuery.updateData([
                    "reservations": reservations
                ])
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
                debugPrint("ERROR: - fetch data error")
            }

            if let querySnapshot = querySnapshot,
                let document = querySnapshot.documents.first {
                if let message = try? document.data(as: Message.self) {
                    self.updateLastMessage(chatRoomID: chatRoomID, message: message)
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
        completion: @escaping ((Result<String>) -> Void)
    ) {
        let members = [senderID, receiverID]
        FIRChatRoomService.shared.getChatRoomByMembers(members: members) { result in
            switch result {
            case .success(let chatRoom):
                let messageRef = FirestoreEndpoint.message(chatRoom.id).colRef.document()

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
                    debugPrint("Error writing Message to Firestore: \(error)")
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

                completion(Result.success(chatRoom.id))
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func updateCurrentMessageStatus(status: AcceptedStatus, currentUser: User, otherUser: User, message: Message) {
        FIRChatRoomService.shared.getChatRoomByMembers(members: [currentUser.id, otherUser.id]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatRoom):
                self.updateMessage(
                    chatRoomID: chatRoom.id,
                    message: message,
                    status: status
                )
            case .failure(let error):
                debugPrint("updateCurrentMessageStatus", error.localizedDescription)
            }
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

        if status == .cancel {
            deleteUserReservation(userID: sender, reservationID: reservation.id)
            deleteUserReservation(userID: receiver, reservationID: reservation.id)
        }

        if sender == UserDefaults.id && status == .cancel && oriStatus == .waiting {
            guard
                let sender = reservation.sender,
                let receiver = reservation.receiver
            else {
                return
            }

            FIRChatRoomService.shared.getChatRoomByMembers(members: [sender, receiver]) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let chatRoom):
                    self.deleteRequestReservationMessage(chatRoomID: chatRoom.id, reservationID: reservation.id, status: .cancel)
                    completion(nil)
                case .failure(let error):
                    debugPrint("replyReservation", error.localizedDescription)
                    completion(nil)
                }
            }
        } else {
            insertMessage(
                senderID: sender,
                receiverID: receiver,
                status: status,
                reservation: reservation
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let chatRoomID):
                    self.deleteRequestReservationMessage(chatRoomID: chatRoomID, reservationID: reservation.id, status: .answer)
                    completion(nil)
                case .failure(let error):
                    debugPrint("replyReservation", error.localizedDescription)
                    completion(nil)
                }
            }
        }
    }

    func deleteRequestReservationMessage(chatRoomID: String, reservationID: String, status: AcceptedStatus) {
        let query = FirestoreEndpoint.message(chatRoomID).colRef
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
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }

    func deleteExpiredReservations() {
        var expiredRsvns: [String] = []
        let group = DispatchGroup()

        group.enter()
        let currentTimestamp = Timestamp()
        let senderQuery = genDeleteRSVNQuery(column: "sender", requestTime: currentTimestamp)

        batchDeleteReservation(query: senderQuery) { rsvns in
            expiredRsvns += rsvns
            group.leave()
        }

        group.enter()

        let receiverQuery = genDeleteRSVNQuery(column: "receiver", requestTime: currentTimestamp)

        batchDeleteReservation(query: receiverQuery) { rsvns in
            expiredRsvns += rsvns
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            FirebaseService.shared.deleteUserRsvnData(expiredRsvns: expiredRsvns)
        }
    }

    private func genDeleteRSVNQuery(column: String, requestTime: Timestamp) -> Query {
        return FirestoreEndpoint.reservation.colRef
            .whereField("isDeleted", isEqualTo: false)
            .whereField("requestTime", isLessThan: requestTime)
            .whereField("receiver", isEqualTo: UserDefaults.id)
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

                batch.commit { error in
                    if let error = error {
                        debugPrint("Error writing batch \(error)")
                    } else {
                        debugPrint("Batch write succeeded.")
                    }
                }
                completion(expiredRsvn)
            }
        }
    }
}
