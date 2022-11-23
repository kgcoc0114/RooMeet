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
    case reportEvent

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

    func upsertUser(uid: String, email: String?, user: User? = nil, completion: @escaping ((Bool, User?) -> Void)) {
        let docRef = FirestoreEndpoint.user.colRef.document(uid)
        print("upserUser ", uid)
        docRef.getDocument { [weak self] document, _ in
            guard let self = self else { return }
            if let document = document, document.exists {
                guard let user = user else {
                    // get user info
                    self.fetchUserByID(userID: uid) { user, _ in
                        if let user = user {
                            UserDefaults.id = user.id
                            completion(false, user)
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
                completion(true, nil)
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
            print("fetchChatRoomDataWithMemberData ", userID)

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
                print("fetchRoomDatabyQuery ", ownerID)

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
                            name: user.name ?? "User"
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
        userBlocks: [String] = [],
        completion: @escaping (([Room]?) -> Void)
    ) {
        var userBlocks = userBlocks
        userBlocks.append(UserDefaults.id)

        FirestoreEndpoint.room.colRef
            .whereField("lat", isLessThanOrEqualTo: northWest.latitude)
            .whereField("lat", isGreaterThanOrEqualTo: southEast.latitude)
            .getDocuments() { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                }

                var roomsWithoutOwnerData: [Room] = []

                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: Room.self)
                            if let long = item.long {
                                if long >= northWest.longitude
                                    && long <= southEast.longitude
                                    && !userBlocks.contains(item.userID) {
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
    }

    // FIXME: add offset for paginate
    func fetchRooms(user: User? = nil, county: String? = nil,  completion: @escaping (([Room]) -> Void)) {
        var query: Query
        var blocks: [String] = [UserDefaults.id]

        guard let user = user else {
            completion([])
            return
        }

        if var tmpBlock = user.blocks {
            tmpBlock.append(UserDefaults.id)
            blocks = tmpBlock
        }

        if let county = county {
            query = FirestoreEndpoint.room.colRef
                .whereField("county", isEqualTo: county)
                .whereField("userID", notIn: blocks)
        } else {
            query = FirestoreEndpoint.room.colRef
                .whereField("userID", notIn: blocks)
        }

        query = query.order(by: "userID", descending: true)

        let group = DispatchGroup()
        getDocuments(query) { [weak self] (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                self?.fetchUserByID(userID: ownerID, index: index) { user, index in
                    if let user = user,
                        let index = index {
                        rooms[index].userData = user
                    }
                    group.leave()
                }
            }

            group.notify(queue: DispatchQueue.main) {
                let sortedRooms = rooms.sorted { roomA, roomB in
                    roomA.createdTime.seconds > roomB.createdTime.seconds
                }
                completion(sortedRooms)
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

    func fetchFavoriteRoomsByUserID(userID: String, completion: @escaping (([Room], [FavoriteRoom]) -> Void)) {
        fetchUserByID(userID: userID) { [unowned self] user, _ in
            guard let user = user else {
                completion([], [])
                return
            }
            self.fetchFavoriteRoomsByRoomID(user: user) { rooms in
                completion(rooms, user.favoriteRooms)
            }
        }
    }

    func fetchFavoriteRoomsByRoomID(user: User, completion: @escaping (([Room]) -> Void)) {
        var rooms: [Room] = []

        let group = DispatchGroup()
        user.favoriteRoomIDs.forEach { roomID in
            group.enter()
            fetchRoomByRoomID(roomID: roomID, user: user) { room in
                rooms.append(room)
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
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

    func fetchRoomsByReservationID(user: User, completion: @escaping (([Reservation]) -> Void)) {
        var reservations: [Reservation] = []
        var rooms: [Room] = []
        let group = DispatchGroup()
        user.reservations.forEach { reservationID in
            group.enter()
            fetchReservationByID(reservationID: reservationID) { [weak self] reservation in
                guard let self = self else { return }

                reservations.append(reservation)

                guard let roomID = reservation.roomID else {
                    return
                }

                self.fetchRoomByRoomID(roomID: roomID, user: user) { room in
                    rooms.append(room)
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let roomIDList = rooms.map { $0.roomID }

            var rsvns = reservations.map { reservation -> Reservation in
                var rsvn = reservation
                if
                    let roomID = rsvn.roomID,
                    let roomIndex = roomIDList.firstIndex(of: roomID) {
                    rsvn.roomDetail = rooms[roomIndex]
                }
                return rsvn
            }

            rsvns = rsvns.sorted() { rsvnA, rsvnB in
                return rsvnA.requestTime!.dateValue() > rsvnB.requestTime!.dateValue()
            }

            completion(rsvns)
        }
    }

    func fetchReservationRoomsByUserID(userID: String, completion: @escaping (([Reservation], User) -> Void)) {
        fetchUserByID(userID: userID) { [weak self] user, _ in
            guard
                let user = user,
                let self = self else {
                return
            }

            self.fetchRoomsByReservationID(user: user) { reservations in
                completion(reservations, user)
            }
        }
    }

    func fetchRoomByRoomID(roomID: String, user: User, completion: @escaping ((Room) -> Void)) {
        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)

        let query = FirestoreEndpoint.room.colRef
            .whereField("roomID", isEqualTo: roomID)
            .whereField("userID", notIn: blocks)

        getDocuments(query) { (rooms: [Room]) in
            rooms.forEach { room in
                var room = room
                self.fetchUserByID(userID: room.userID) { user, _ in
                    room.userData = user
                    completion(room)
                }
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
        var currentUser: User
        fetchUserByID(userID: UserDefaults.id) { user, _ in
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

                                let otherUser = item.members.filter { $0 != UserDefaults.id }.first

                                let blocks = user?.blocks ?? []

                                if item.members[0] != item.members[1] && !blocks.contains(otherUser!) {
                                    chatRooms.append(item)
                                }
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
                    completion([],error)
                }
            }
        }
    }

    func insertBlock(blockedUser: String, completion: @escaping ((Error?) -> Void)) {
        let query = FirestoreEndpoint.user.colRef.document(UserDefaults.id)
        do {
            try query.updateData([
                "blocks": FieldValue.arrayUnion([blockedUser])
            ])
            completion(nil)
        } catch {
            completion(error)
        }

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
