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
    case call
    case reservation

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
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()

    var currentTimestamp = Timestamp()

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
        let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", arrayContains: UserDefaults.id)

        getDocuments(query) { (chatRooms: [ChatRoom]) in
            completion(chatRooms)
        }
    }

    func upsertUser(uid: String, email: String?, user: User? = nil, completion: @escaping ((Bool) -> Void)) {
        let docRef = FirestoreEndpoint.user.colRef.document(uid)

        docRef.getDocument { [weak self] document, _ in
            guard let `self` = self else { return }
            if let document = document, document.exists {
                guard let user = user else {
                    // get user info
                    self.fetchUserByID(userID: uid) { user, _ in
                        if let user = user {
                            UserDefaults.id = user.id

                            gCurrentUser = user
                            completion(false)
                        }
                    }
                    return
                }
                docRef.updateData(user.dictionary)
            } else {
                // create new user
                var updateData = [
                    "id": uid
                ]

                if let email = email {
                    updateData["email"] = email
                }

                docRef.setData(updateData)

                // new user -> should present information page
                completion(true)
            }
        }
    }

    func getChatRoomByUserID(userA: String, userB: String, completion: @escaping ((ChatRoom) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", arrayContains: userA)

        getDocuments(query) { [weak self] (chatRooms: [ChatRoom]) in
            var chatRooms = chatRooms
            chatRooms = chatRooms.filter({ $0.members.contains(userB)
            })
            print(chatRooms)
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
                    member != UserDefaults.id
                }

                if !members.isEmpty {
                    let memberID = members[0]
                    group.enter()
                    self?.fetchUserByID(userID: memberID, index: index) { user, index in
                        if let user = user {
                            chatRooms[index!].member = ChatMember(id: memberID, profilePhoto: user.profilePhoto!, name: user.name!)
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
                member != UserDefaults.id
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
                            name: user.name!
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

    func fetchRoomsByUserID(userID: String, completion: @escaping (([Room]) -> Void)) {
        let query = FirestoreEndpoint.room.colRef
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdTime", descending: true)

        let group = DispatchGroup()
        getDocuments(query) { (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                self.fetchUserByID(userID: ownerID, index: index) { user, index in
                    if
                        let user = user,
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

    func fetchFavoriteRoomsByUserID(userID: String, completion: @escaping (([Room]) -> Void)) {
        fetchUserByID(userID: userID) { [unowned self] user, _ in
            guard let user = user else {
                completion([])
                return
            }
            self.fetchFavoriteRoomsByRoomID(roomIDList: user.favoriteRoomIDs) { rooms in
                completion(rooms)
            }
        }
    }

    func fetchFavoriteRoomsByRoomID(roomIDList: [String]?, completion: @escaping (([Room]) -> Void)) {
        guard let roomIDList = roomIDList else {
            return
        }
        let group = DispatchGroup()
        roomIDList.forEach { roomID in
            group.enter()
            fetchRoomByRoomID(roomID: roomID) { room in
                guard let roomID = room.roomID else { return }
                let index = roomIDList.firstIndex(of: roomID)
                gCurrentUser.favoriteRooms[index!].room = room
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let rooms = gCurrentUser.favoriteRooms.map { favRoom in
                return favRoom.room!
            }
            completion(rooms)
        }
    }

    func fetchReservationByID(reservationID: String, completion: @escaping ((Reservation) -> Void)) {
        let query = FirestoreEndpoint.reservation.colRef.document(reservationID)

        query.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let reservation = try document.data(as: Reservation.self)
                    completion(reservation)
                } catch {
                    print("ERROR: \(error.localizedDescription)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func fetchRoomsByReservationID(reservationList: [String]?, completion: @escaping (([Reservation]) -> Void)) {
        guard let reservationList = reservationList else {
            return
        }
        var reservations: [Reservation] = []
        var rooms: [Room] = []
        let group = DispatchGroup()
        reservationList.enumerated().forEach { index, reservationID in
            group.enter()
            fetchReservationByID(reservationID: reservationID) { [weak self] reservation in
                reservations.append(reservation)
                guard let roomID = reservation.roomID else {
                    return
                }
                self?.fetchRoomByRoomID(roomID: roomID) { room in
                    rooms.append(room)
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let roomIDList = rooms.map({ room in
                room.roomID
            })

            let rsvns = reservations.map { reservation -> Reservation in
                var rsvn = reservation
                if let roomID = rsvn.roomID,
                   let roomIndex = roomIDList.firstIndex(of: roomID) {
                    rsvn.roomDetail = rooms[roomIndex]
                }
                return rsvn
            }
            completion(rsvns)
        }
    }

    func fetchReservationRoomsByUserID(userID: String, completion: @escaping (([Reservation]) -> Void)) {
        fetchUserByID(userID: userID) {[weak self] user, _ in
            guard let user = user,
                  let self = self else {
                return
            }

            self.fetchRoomsByReservationID(reservationList: user.reservations) { reservations in
                completion(reservations)
            }
        }
    }

    func fetchRoomByRoomID(roomID: String, completion: @escaping ((Room) -> Void)) {
        let query = FirestoreEndpoint.room.colRef.document(roomID)

        query.getDocument { [weak self] document, error in
            guard let `self` = self else { return }
            if let document = document, document.exists {
                do {
                    var room = try document.data(as: Room.self)

                    self.fetchUserByID(userID: room.userID) { user, _ in
                        room.userData = user

                        completion(room)
                    }
                } catch {
                    print("ERROR: \(error.localizedDescription)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func fetchRoomWithOwnerData(roomID: String, completion: @escaping ((Room) -> Void)) {
        let query = FirestoreEndpoint.room.colRef.document(roomID)

        query.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let room = try document.data(as: Room.self)
                    completion(room)
                } catch {
                    print("ERROR: \(error.localizedDescription)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func fetchRoomCountsOwnByUserID(userID: String, completion: @escaping ((Int) -> Void)) {
        let query = FirestoreEndpoint.room.colRef
            .whereField("userID", isEqualTo: userID)
        getDocuments(query) { (rooms: [Room]) in
            completion(rooms.count)
        }
    }

    func fetchRoomsOwnByUserID(roomIDList: [String]?, completion: @escaping (([Room]) -> Void)) {
        guard let roomIDList = roomIDList else {
            return
        }
        var rooms: [Room] = []
        let group = DispatchGroup()
        roomIDList.forEach { roomID in
            group.enter()
            fetchRoomByRoomID(roomID: roomID) { room in
                rooms.append(room)
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion(rooms)
        }
    }
}

extension FirebaseService {
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
            .whereField("members", arrayContains: UserDefaults.id)
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


    func updateUserFavRsvnData(reservations: [String], favoriteRooms: [FavoriteRoom]) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)

        query.updateData([
            "reservations": reservations,
            "favoriteRooms": []
        ])

        let favoriteRoomsMap = favoriteRooms.map { favoriteRoom in
            favoriteRoom.dictionary
        }

        query.updateData([
            "favoriteRooms": FieldValue.arrayUnion(favoriteRoomsMap)
        ])
    }
}

// MARK: - room
extension FirebaseService {
    func updateRoomInfo(roomID: String, room: Room, completion: @escaping ((Error?) -> Void)) {
        FirestoreEndpoint.room.colRef.document(roomID).delete() { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else {
                self.insertRoom(room: room, roomID: roomID) { error in
                    completion(error)
                }
            }
        }
    }

    func insertRoom(room: Room, roomID: String? = nil, completion: @escaping ((Error?) -> Void)) {
        var docRef = FirestoreEndpoint.room.colRef.document()

        var room = room

        if let roomID = roomID {
            docRef = FirestoreEndpoint.room.colRef.document(roomID)
        }

        room.roomID = roomID ?? docRef.documentID

        do {
            try docRef.setData(from: room, completion: { error in
                completion(error)
            })
        } catch {
            completion(error)
        }
    }
}
