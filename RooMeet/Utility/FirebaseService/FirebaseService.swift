//
//  FirebaseService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

enum FirestoreEndpoint {
    case room
    case chatRoom
    case user
    case call
    case reservation
    case reportEvent
    case furniture
    case message(String)

    var colRef: CollectionReference {
        let database = Firestore.firestore()

        switch self {
        case .room:
            return database.collection("Room")
        case .call:
            return database.collection("Call")
        case .chatRoom:
            return database.collection("ChatRoom")
        case .user:
            return database.collection("User")
        case .reservation:
            return database.collection("Reservation")
        case .reportEvent:
            return database.collection("ReportEvent")
        case .furniture:
            return database.collection("Furniture")
        case .message(let chatRoomID):
            return database.collection("ChatRoom").document(chatRoomID).collection("Message")
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()

    private init(){}

    var currentTimestamp = Timestamp()

    var database = Firestore.firestore()

    func getDocument<T: Codable>(_ docRef: DocumentReference, completion: @escaping (T?) -> Void) {
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            completion(self.parseDocument(snapshot: snapshot, error: error))
        }
    }

    func getDocuments<T: Codable>(_ query: Query, complection: @escaping ([T]) -> Void) {
        query.getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            complection(self.parseDocuments(querySnapshot: querySnapshot, error: error))
        }
    }

    func delete(_ docRef: DocumentReference) {
        docRef.delete()
    }

    func setData(_ documentData: [String: Any], at docRef: DocumentReference) {
        docRef.setData(documentData)
    }

    func setData<T: Encodable>(_ data: T, at docRef: DocumentReference) {
        do {
            try docRef.setData(from: data)
        } catch {
            print("DEBUG: Error encoding \(data.self) data -", error.localizedDescription)
        }
    }

    private func parseDocument<T: Codable>(snapshot: DocumentSnapshot?, error: Error?) -> T? {
        guard let snapshot = snapshot, snapshot.exists else {
            let errorMessage = error?.localizedDescription ?? ""
            print("DEBUG: Nil document", errorMessage)
            return nil
        }

        var model: T?
        do {
            model = try snapshot.data(as: T.self)
        } catch {
            print("DEBUG: Error decoding \(T.self) data -", error.localizedDescription)
        }
        return model
    }

    func parseDocuments<T: Codable>(querySnapshot: QuerySnapshot?, error: Error?) -> [T] {
        if let error = error {
            print("Error getting documents: \(error)")
        }

        var itemList: [T] = []
        if let querySnapshot = querySnapshot {
            querySnapshot.documents.forEach { document in
                do {
                    let item = try document.data(as: T.self)
                    itemList.append(item)
                } catch {
                    print("DEBUG: Error decoding \(T.self) data -", error.localizedDescription)
                }
            }
            return itemList
        }
        return itemList
    }

    func fetchUserByID(userID: String, index: Int? = nil, completion: @escaping ((User?, Int?) -> Void)) {
        let docRef = Firestore.firestore().collection("User").document(userID)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let item = try document.data(as: User.self)
                    completion(item, index)
                } catch let error {
                    print("ERROR: fetchUserByID - \(error.localizedDescription)")
                }
            } else {
                completion(User(id: "notExist", name: "不明用戶"), index)
            }
        }
    }
}

extension FirebaseService {
    func fetchReservationByID(reservationID: String, completion: @escaping ((Result<Reservation>) -> Void)) {
        let query = FirestoreEndpoint.reservation.colRef
            .whereField("id", isEqualTo: reservationID)
            .whereField("isDeleted", isEqualTo: false)

        getDocuments(query) { (reservations: [Reservation]) in
            if reservations.isEmpty {
                completion(Result.failure(RMError.noData))
            } else {
                completion(Result.success(reservations[0]))
            }
        }
    }
}

extension FirebaseService {
    // MARK: - Room Detail Page - Like
    func updateUserFavoriteRoomsData(favoriteRooms: [FavoriteRoom]) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)

        query.updateData([
            "favoriteRooms": []
        ])

        let favoriteRoomsMap = favoriteRooms.map { favoriteRoom in
            favoriteRoom.dictionary
        }

        query.updateData([
            "favoriteRooms": favoriteRoomsMap
        ])
    }

    func updateUserFavData(favoriteRooms: [FavoriteRoom]) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)

        query.updateData([
            "favoriteRooms": []
        ])

        let favoriteRoomsMap = favoriteRooms.map { favoriteRoom in
            favoriteRoom.dictionary
        }

        query.updateData([
            "favoriteRooms": FieldValue.arrayUnion(favoriteRoomsMap)
        ])
    }

    func deleteUserRsvnData(expiredRsvns: [String]) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)

        query.getDocument { document, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let document = document {
                    let user = try? document.data(as: User.self)
                    if let user = user {
                        let availableRsvns = user.reservations.filter { !expiredRsvns.contains($0)
                        }

                        query.updateData([
                            "reservations": []
                        ])

                        query.updateData([
                            "reservations": availableRsvns
                        ])
                    }
                }
            }
        }
    }
}
