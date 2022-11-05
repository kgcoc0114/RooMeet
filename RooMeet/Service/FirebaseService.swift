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
import MapKit

enum FirestoreEndpoint {
    case room
    case chatRoom
    case user

    var docRef: CollectionReference {
        let database = Firestore.firestore()

        switch self {
        case .room:
            return database.collection("Room")
        case .chatRoom:
            return database.collection("ChatRoom")
        case .user:
            return database.collection("User")
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()

    func getDocuments<T: Codable>(_ query: Query, complection: @escaping ([T]) -> Void) {
        query.getDocuments { [weak self] querySnapshot, error in
            guard let `self` = self else { return }
            complection(self.parseDocuments(querySnapshot: querySnapshot, error: error))
        }
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

    func fetchRoomByArea(postalCode: String, completion: @escaping (([Room]) -> Void)) {
        let query = FirestoreEndpoint.room.docRef.whereField("postalCode", isEqualTo: postalCode)
        self.getDocuments(query) { (rooms: [Room]) in
            completion(rooms)
        }
    }

    func fetchUserByID(userID: String, index: Int? = nil, completion: @escaping ((User?, Int?) -> Void)) {
        let docRef = FirestoreEndpoint.user.docRef.document(userID)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let item = try document.data(as: User.self)
                    completion(item, index)
                } catch let error {
                    print("ERROR: fetchUserByID - \(error.localizedDescription)")
                }
            } else {
                completion(nil, index)
            }
        }
    }

    func fetchChatRoomsByUserID(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.docRef.whereField("members", arrayContains: User.mockUser.id)

        getDocuments(query) { (chatRooms: [ChatRoom]) in
            completion(chatRooms)
        }
    }

    func fetchChatRoomDataWithMemberData(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
        fetchChatRoomsByUserID(userID: userID) { [weak self] roomsResult in
            let group = DispatchGroup()
            var chatRooms = roomsResult
            chatRooms.enumerated().forEach { index, roomResult in
                var chatRoom = roomResult
                let memberID = chatRoom.members.filter { member in
                    member != userID
                }[0]
                group.enter()
                self?.fetchUserByID(userID: memberID, index: index) { user, index in
                    if let user = user {
                        chatRooms[index!].member = ChatMember(id: memberID, profilePhoto: user.profilePhoto, name: user.name)
                    }
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.main) {
                completion(chatRooms)
            }
        }
    }

    func fetchRoomMemberData(chatRooms rooms: [ChatRoom], completion: @escaping (([ChatRoom]) -> Void)) {
        let group = DispatchGroup()
        var chatRooms = rooms
        chatRooms.enumerated().forEach { index, roomResult in
            var chatRoom = roomResult
            let memberID = chatRoom.members.filter { member in
                member != User.mockUser.id
            }[0]
            group.enter()
            self.fetchUserByID(userID: memberID, index: index) { user, index in
                if let user = user {
                    chatRooms[index!].member = ChatMember(id: memberID, profilePhoto: user.profilePhoto, name: user.name)
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion(chatRooms)
        }
    }

    func fetchRoomByCoordinate(
        northWest: CLLocationCoordinate2D,
        southEast: CLLocationCoordinate2D,
        completion: @escaping (([Room]?) -> Void)
    ) {
        FirestoreEndpoint.room.docRef
            .whereField("lat", isLessThanOrEqualTo: northWest.latitude)
            .whereField("lat", isGreaterThanOrEqualTo: southEast.latitude)
            .getDocuments() { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                }

                var rooms: [Room] = []
                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: Room.self)
                            if let long = item.long {
                                if long >= northWest.longitude && long <= southEast.longitude {
                                    rooms.append(item)
                                }
                            }
                        } catch {
                            print("DEBUG: Error decoding \(Room.self) data -", error.localizedDescription)
                        }
                    }
                    completion(rooms)
                }
            }
    }

    func fetchMessagesbyRoomID(roomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.docRef.document(roomID).collection("Message")

        query.getDocuments(completion: { querySnapshot, error in
            if let error = error {
                completion(nil, error)
                print("ERROR: getting documents: \(error.localizedDescription)")
            }

            var messages: [Message] = []
            if let querySnapshot = querySnapshot {
                querySnapshot.documents.forEach { document in
                    do {
                        let item = try document.data(as: Message.self)
                        messages.append(item)
                    } catch let DecodingError.dataCorrupted(context) {
                        print(context)
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.typeMismatch(type, context) {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("ERROR: ", error.localizedDescription)
                    }
                }
                completion(messages, nil)
            }
        })
    }

    func listenToMessageUpdate(roomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        FirestoreEndpoint.chatRoom.docRef
            .document(roomID)
            .collection("Message")
            .order(by: "createdTime", descending: false)
            .addSnapshotListener({ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    completion(nil, error)
                    return
                }

                var messages: [Message] = []

                snapshot.documents.forEach { document in
                    do {
                        let item = try document.data(as: Message.self)
                        messages.append(item)
                    } catch let DecodingError.dataCorrupted(context) {
                        print(context)
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.typeMismatch(type, context) {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("error: ", error)
                        completion(nil, error)
                    }
                }
                completion(messages, nil)
            })
    }


    func listenToChatRoomUpdate(completion: @escaping (([ChatRoom]?, Error?) -> Void)) {
        FirestoreEndpoint.chatRoom.docRef
            .whereField("members", arrayContains: User.mockUser.id)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener({ querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completion(nil, error)
                }

                var chatRooms: [ChatRoom] = []
                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: ChatRoom.self)
                            chatRooms.append(item)
                        } catch let DecodingError.dataCorrupted(context) {
                            print(context)
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("Key '\(key)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.valueNotFound(value, context) {
                            print("Value '\(value)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.typeMismatch(type, context) {
                            print("Type '\(type)' mismatch:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch {
                            print("ERROR: ", error.localizedDescription)
                        }
                    }

                    FirebaseService.shared.fetchRoomMemberData(chatRooms: chatRooms) { chatRooms in
                        completion(chatRooms, nil)
                    }
                }
            })
    }
}