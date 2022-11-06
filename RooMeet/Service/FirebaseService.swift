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

    var colRef: CollectionReference {
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
        let query = FirestoreEndpoint.room.colRef.whereField("postalCode", isEqualTo: postalCode)
        self.getDocuments(query) { (rooms: [Room]) in
            completion(rooms)
        }
    }

    func fetchUserByID(userID: String, index: Int? = nil, completion: @escaping ((User?, Int?) -> Void)) {
        let docRef = FirestoreEndpoint.user.colRef.document(userID)

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
        let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", arrayContains: gCurrentUser.id)

        getDocuments(query) { (chatRooms: [ChatRoom]) in
            completion(chatRooms)
        }
    }

    func upsertChatRoomByUserID(userA: String, userB: String, completion: @escaping ((ChatRoom) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", isEqualTo: [userA, userB])

        getDocuments(query) { [weak self] (chatRooms: [ChatRoom]) in
            if chatRooms.isEmpty {
                self?.insertNewChatRoom(userA: userA, userB: userB) { chatRoom, _ in
                    if let chatRoom = chatRoom {
                        self?.fetchRoomMemberData(chatRooms: [chatRoom], completion: { chatRooms in
                            if let returnChatRoom = chatRooms.first {
                                completion(returnChatRoom)
                            }
                        })
                    }
                }
            } else {
                self?.fetchRoomMemberData(chatRooms: chatRooms, completion: { chatRooms in
                    if let returnChatRoom = chatRooms.first {
                        completion(returnChatRoom)
                    }
                })
            }
        }
    }

    func insertNewChatRoom(userA: String, userB: String, completion: @escaping ((ChatRoom?, Error?) -> Void)) {
        let colRef = FirestoreEndpoint.chatRoom.colRef
        let docRef = colRef.document()
        let chatroom = ChatRoom(id: docRef.documentID, members: [userA, userB], messages: nil, messagesContent: nil, lastMessage: nil, lastUpdated: nil)

        do {
            try docRef.setData(from: chatroom)
            completion(chatroom, nil)
        } catch let error {
            print(error.localizedDescription)
            completion(nil, error)
        }
    }

    func fetchChatRoomDataWithMemberData(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
        fetchChatRoomsByUserID(userID: userID) { [weak self] roomsResult in
            let group = DispatchGroup()
            var chatRooms = roomsResult
            chatRooms.enumerated().forEach { index, roomResult in
                var chatRoom = roomResult
                let members = chatRoom.members.filter { member in
                    member != gCurrentUser.id
                }

                if !members.isEmpty {
                    let memberID = members[0]
                    group.enter()
                    self?.fetchUserByID(userID: memberID, index: index) { user, index in
                        if let user = user {
                            chatRooms[index!].member = ChatMember(id: memberID, profilePhoto: user.profilePhoto, name: user.name)
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: DispatchQueue.main) {
                completion(chatRooms)
            }
        }
    }

    func fetchRoomDatabyQuery(query: Query, completion: @escaping (([Room]) -> Void)) {
        let group = DispatchGroup()
        getDocuments(query) { (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                self.fetchUserByID(userID: ownerID, index: index) { user, index in
                    if let user = user,
                       let index = index {
                        rooms[index].userData = user
                    }
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.main) {
                completion(rooms)
            }
        }
    }

    func fetchRoomMemberData(chatRooms rooms: [ChatRoom], completion: @escaping (([ChatRoom]) -> Void)) {
        let group = DispatchGroup()
        var chatRooms = rooms
        chatRooms.enumerated().forEach { index, roomResult in
            var chatRoom = roomResult
            let members = chatRoom.members.filter { member in
                member != gCurrentUser.id
            }

            if !members.isEmpty {
                let memberID = members[0]
                group.enter()
                self.fetchUserByID(userID: memberID, index: index) { user, index in
                    if let user = user,
                        let index = index {
                        chatRooms[index].member = ChatMember(
                            id: memberID,
                            profilePhoto: user.profilePhoto,
                            name: user.name
                        )
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion(chatRooms)
        }
    }

    // MARK: - Explore Page
    func fetchRoomByCoordinate(
        northWest: CLLocationCoordinate2D,
        southEast: CLLocationCoordinate2D,
        completion: @escaping (([Room]?) -> Void)
    ) {
        FirestoreEndpoint.room.colRef
            .whereField("lat", isLessThanOrEqualTo: northWest.latitude)
            .whereField("lat", isGreaterThanOrEqualTo: southEast.latitude)
            .getDocuments() {
                querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                }

                var roomsWithoutOwnerData: [Room] = []
                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: Room.self)
                            if let long = item.long {
                                if long >= northWest.longitude && long <= southEast.longitude {
                                    roomsWithoutOwnerData.append(item)
                                }
                            }
                        } catch {
                            print("DEBUG: Error decoding \(Room.self) data -", error.localizedDescription)
                        }
                    }

                    let group = DispatchGroup()

                    var rooms = roomsWithoutOwnerData
                    rooms.enumerated().forEach { index, roomResult in
                        let ownerID = roomResult.userID
                        group.enter()
                        self.fetchUserByID(userID: ownerID, index: index) { user, index in
                            if let user = user {
                                rooms[index!].userData = user
                            }
                            group.leave()
                        }
                    }
                    group.notify(queue: DispatchQueue.main) {
                        completion(rooms)
                    }
                }
            }
    }

    // FIXME: add offset for paginate
    func fetchRooms(county: String? = nil, completion: @escaping (([Room]) -> Void)) {
        var query: Query
        if let county = county {
            query = FirestoreEndpoint.room.colRef.whereField("county", isEqualTo: county)
        } else {
            query = FirestoreEndpoint.room.colRef
        }

        query = query.order(by: "createdTime", descending: true)

        let group = DispatchGroup()
        getDocuments(query) { (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                self.fetchUserByID(userID: ownerID, index: index) { user, index in
                    if let user = user,
                       let index = index {
                        rooms[index].userData = user
                    }
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.main) {
                completion(rooms)
            }
        }
    }

    // MARK: - Chat Room
    func fetchMessagesbyChatRoomID(chatRoomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.colRef.document(chatRoomID).collection("Message")

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
        FirestoreEndpoint.chatRoom.colRef
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
        FirestoreEndpoint.chatRoom.colRef
            .whereField("members", arrayContains: gCurrentUser.id)
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
                            if item.members[0] != item.members[1] {
                                chatRooms.append(item)
                            }
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

    // MARK: - Room Detail Page - Like
    func updateUserLikeData() {
        let query = FirestoreEndpoint.user.colRef.document(gCurrentUser.id)

        query.updateData([
            "like": gCurrentUser.like
        ])
    }
}
