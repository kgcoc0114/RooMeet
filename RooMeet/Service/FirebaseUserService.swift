//
//  FirebaseUserService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/27.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Delete Account
extension FirebaseService {
    func deleteAccount(userID: String, completion: @escaping ((Result<String>) -> Void)) {
        let group = DispatchGroup()
        group.enter()
        deleteUser(userID: userID) { _ in
            group.leave()
        }

        group.enter()
        deleteRoomPosts(userID: userID) { result in
            switch result {
            case .success(_):
                print("SUCCESS: - Delete Room Posts")
            case .failure(let error):
                print("ERROR: - Delete Room Posts, \(error.localizedDescription)")
            }
            group.leave()
        }

        group.enter()
        deleteReservations(userID: userID) { result in
            switch result {
            case .success(_):
                print("SUCCESS: - Delete Reservations")
            case .failure(let error):
                print("ERROR: - Delete Reservations, \(error.localizedDescription)")
            }
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            completion(Result.success(""))
        }
    }

    func deleteUser(userID: String, completion: @escaping ((Result<String>) -> Void)) {
        FirestoreEndpoint.user.colRef.document(userID).delete { error in
            if let error = error {
                completion(Result.failure(error))
            } else {
                completion(Result.success("SUCCESS: - User delete successfully."))
            }
        }
    }

    func deleteReservations(userID: String, completion: @escaping ((Result<String>) -> Void)) {
        let group = DispatchGroup()
        // get sender user's reservations
        group.enter()
        let senderRef = FirestoreEndpoint.reservation.colRef.whereField("sender", isEqualTo: userID)

        batchDeleteReservation(query: senderRef) { _ in
            group.leave()
        }


        // get receiver user's reservations
        group.enter()
        let receiverRef = FirestoreEndpoint.reservation.colRef.whereField("receiver", isEqualTo: userID)
        batchDeleteReservation(query: receiverRef) { _ in
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            completion(Result.success(""))
        }
    }

    func batchDeleteReservation(query: Query, completion: @escaping ((Result<String>) -> Void)) {
        let batch = Firestore.firestore().batch()

        query.getDocuments { snapshot, _ in
            guard let snapshot = snapshot else {
                return
            }

            snapshot.documents.forEach { document in
                batch.updateData(["isDeleted": true], forDocument: document.reference)
            }

            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error writing batch \(error)")
                    completion(Result.failure(error))
                } else {
                    print("Batch write succeeded.")
                    completion(Result.success(""))
                }
            }
        }
    }

    func deleteRoomPosts(userID: String, completion: @escaping ((Result<String>) -> Void)) {
        // Get new write batch
        let batch = Firestore.firestore().batch()

        // get user's room posts
        let roomRef = FirestoreEndpoint.room.colRef.whereField("userID", isEqualTo: userID)

        roomRef.getDocuments { snapshot, _ in
            guard let snapshot = snapshot else {
                return
            }

            snapshot.documents.forEach { document in
                batch.updateData(["isDeleted": true], forDocument: document.reference)
            }

            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error writing batch \(error)")
                    completion(Result.failure(error))
                } else {
                    print("Batch write succeeded.")
                    completion(Result.success(""))
                }
            }
        }
    }
}

// MARK: - User Action
extension FirebaseService {
    func fatchBlockUsers(completion: @escaping (([User], Error?) -> Void)) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)
        query.getDocument { document, error in
            if let error = error {
                completion([], error)
            }

            if let document = document {
                do {
                    let user = try document.data(as: User.self)

                    if let blocks = user.blocks {
                        let group = DispatchGroup()
                        var users: [User] = []

                        blocks.forEach { blockID in
                            group.enter()
                            self.fetchUserByID(userID: blockID) { user, _ in
                                guard let user = user else {
                                    return
                                }
                                users.append(user)
                                group.leave()
                            }
                        }

                        group.notify(queue: DispatchQueue.main) {
                            completion(users, nil)
                        }
                    }
                } catch {
                    completion([], error)
                }
            }
        }
    }

    func insertBlock(blockedUser: String) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)
        query.updateData([
            "blocks": FieldValue.arrayUnion([blockedUser])
        ])
    }

    func deleteBlock(blockedUsers: [String]) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)
        query.updateData([
            "blocks": FieldValue.arrayRemove(blockedUsers)
        ])
    }

    func insertReportEvent(event: ReportEvent, completion: @escaping ((Error?) -> Void)) {
        let query = FirestoreEndpoint.reportEvent.colRef.document()
        do {
            try query.setData(from: event)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
