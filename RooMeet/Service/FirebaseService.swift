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
    case furniture

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
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()

    var currentTimestamp = Timestamp()

    var database = Firestore.firestore()

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
                completion(User(id: "notExist", name: "不明用戶"), index)
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
            guard let self = self else { return }
            var chatRooms = chatRooms
            chatRooms = chatRooms.filter { $0.members.contains(userB) }

            if chatRooms.isEmpty {
                self.insertNewChatRoom(userA: userA, userB: userB) { chatRoom, _ in
                    if let chatRoom = chatRoom {
                        self.fetchRoomMemberData(chatRooms: [chatRoom]) { chatRooms in
                            if let returnChatRoom = chatRooms.first {
                                completion(returnChatRoom)
                            }
                        }
                    }
                }
            } else {
                self.fetchRoomMemberData(chatRooms: chatRooms) { chatRooms in
                    if let returnChatRoom = chatRooms.first {
                        completion(returnChatRoom)
                    }
                }
            }
        }
    }

    func insertNewChatRoom(userA: String, userB: String, completion: @escaping ((ChatRoom?, Error?) -> Void)) {
        let colRef = FirestoreEndpoint.chatRoom.colRef
        let docRef = colRef.document()
        let chatroom = ChatRoom(
            id: docRef.documentID,
            members: [userA, userB],
            messages: nil,
            messagesContent: nil,
            lastMessage: nil,
            lastUpdated: nil
        )

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
                let chatRoom = roomResult
                let members = chatRoom.members.filter { member in
                    member != UserDefaults.id
                }

                if !members.isEmpty {
                    let memberID = members[0]
                    group.enter()
                    self?.fetchUserByID(userID: memberID, index: index) { user, index in
                        if let user = user,
                            let index = index {
                            chatRooms[index].member = ChatMember(
                                id: memberID,
                                profilePhoto: user.profilePhoto,
                                name: user.name ?? "不明用戶")
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

    func fetchRoomDatabyQuery(user: User, query: Query, completion: @escaping (([Room]) -> Void)) {
        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)
        print(blocks)

        let group = DispatchGroup()
        var rooms: [Room] = []
        var users: [User] = []

        group.enter()
        getDocuments(query) { (tmpRooms: [Room]) in
            rooms += tmpRooms
            print("rooms.count = ", rooms.count)
            tmpRooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                if !blocks.contains(ownerID) {
                    group.enter()
                    self.fetchUserByID(userID: ownerID, index: index) { user, _ in
                        if let user = user {
                            users.append(user)
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }

        let queryNil = FirestoreEndpoint.room.colRef.whereField("roomMinPrice", isEqualTo: -1)
        group.enter()
        getDocuments(queryNil) { (tmpRooms: [Room]) in
            rooms += tmpRooms
            print("rooms.count = ", rooms.count)
            tmpRooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                if !blocks.contains(ownerID) {
                    group.enter()
                    self.fetchUserByID(userID: ownerID, index: index) { user, _ in
                        if let user = user {
                            users.append(user)
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            let userIDs = users.map { $0.id }
            let filterRooms = rooms
                .map { room -> Room in
                    var room = room
                    if let uIndex = userIDs.firstIndex(of: room.userID) {
                        room.userData = users[uIndex]
                    }
                    return room
                }
                .filter { $0.userData != nil }
                .sorted { $0.createdTime.seconds > $1.createdTime.seconds }
            completion(filterRooms)
        }
    }

    func fetchRoomMemberData(chatRooms rooms: [ChatRoom], completion: @escaping (([ChatRoom]) -> Void)) {
        let group = DispatchGroup()
        var chatRooms = rooms
        chatRooms.enumerated().forEach { index, roomResult in
            let chatRoom = roomResult
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
            .whereField("isDeleted", isEqualTo: false)
            .getDocuments { [weak self] querySnapshot, error in
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
    func fetchRooms(user: User? = nil, county: String? = nil, completion: @escaping (([Room]) -> Void)) {
        var query: Query

        guard let user = user else {
            completion([])
            return
        }

        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)

        if let county = county {
            query = FirestoreEndpoint.room.colRef
                .whereField("county", isEqualTo: county)
                .whereField("isDeleted", isEqualTo: false)
        } else {
            query = FirestoreEndpoint.room.colRef
                .whereField("isDeleted", isEqualTo: false)
        }

        query = query.order(by: "userID", descending: true)

        let group = DispatchGroup()
        getDocuments(query) { [weak self] (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                if !blocks.contains(roomResult.userID) {
                    self?.fetchUserByID(userID: ownerID, index: index) { user, index in
                        if let user = user,
                            let index = index {
                            rooms[index].userData = user
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: DispatchQueue.main) {
                let filterRooms = rooms.filter { $0.userData != nil }

                let sortedRooms = filterRooms.sorted { roomA, roomB in
                    roomA.createdTime.seconds > roomB.createdTime.seconds
                }
                completion(sortedRooms)
            }
        }
    }

    func fetchRoomsByUserID(userID: String, completion: @escaping (([Room]) -> Void)) {
        let query = FirestoreEndpoint.room.colRef
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: false)
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
                let filterRoom = rooms.filter { $0.userData != nil }
                completion(filterRoom)
            }
        }
    }
}

extension FirebaseService {
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
                if let room = room {
                    rooms.append(room)
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let sorted = rooms
                .filter { $0.isDeleted == false }
                .sorted { $0.createdTime.seconds > $1.createdTime.seconds }
            completion(sorted)
        }
    }

    func fetchReservationByID(reservationID: String, completion: @escaping ((Result<Reservation>) -> Void)) {
        let query = FirestoreEndpoint.reservation.colRef
            .whereField("id", isEqualTo: reservationID)
            .whereField("isDeleted", isEqualTo: false)

        query.getDocuments { querySnapshot, error in
            if
                let querySnapshot = querySnapshot,
                !querySnapshot.isEmpty {
                querySnapshot.documents.forEach { document in
                    do {
                        let reservation = try document.data(as: Reservation.self)
                        completion(Result.success(reservation))
                    } catch {
                        completion(Result.failure(error))
                    }
                }
            } else {
                completion(Result.failure(RMError.noData))
            }
        }
    }

    func fetchRoomsByReservationID(user: User, completion: @escaping (([Reservation]) -> Void)) {
        var reservations: [Reservation] = []
        var rooms: [Room] = []
        let group = DispatchGroup()
        user.reservations.forEach { reservationID in
            group.enter()
            fetchReservationByID(reservationID: reservationID) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let reservation):
                    reservations.append(reservation)
                    guard let roomID = reservation.roomID else {
                        return
                    }
                    self.fetchRoomByRoomID(roomID: roomID, user: user) { room in
                        if let room = room {
                            rooms.append(room)
                        }

                        group.leave()
                    }
                case .failure(_):
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let roomIDList = rooms.map { $0.roomID }

            var rsvns = reservations
                .map { reservation -> Reservation in
                    var rsvn = reservation
                    if
                        let roomID = rsvn.roomID,
                        let roomIndex = roomIDList.firstIndex(of: roomID) {
                        rsvn.roomDetail = rooms[roomIndex]
                    }
                    return rsvn
                }
                .filter { $0.roomDetail != nil && $0.roomDetail?.isDeleted == false }

            rsvns = rsvns.sorted { rsvnA, rsvnB in
                guard
                    let requestTimeA = rsvnA.requestTime,
                    let requestTimeB = rsvnB.requestTime else {
                    return rsvnA.createdTime.dateValue() > rsvnB.createdTime.dateValue()
                }
                return requestTimeA.dateValue() > requestTimeB.dateValue()
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

    func fetchRoomByRoomID(roomID: String, user: User, completion: @escaping ((Room?) -> Void)) {
        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)

        let query = FirestoreEndpoint.room.colRef
            .whereField("roomID", isEqualTo: roomID)

        query.getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if error != nil {
                completion(nil)
            } else {
                guard let querySnapshot = querySnapshot else {
                    completion(nil)
                    return
                }
                querySnapshot.documents.forEach { document in
                    do {
                        var item = try document.data(as: Room.self)

                        self.fetchUserByID(userID: item.userID) { user, _ in
                            if let user = user {
                                item.userData = user
                            }
                            completion(item)
                        }
                    } catch {
                        print("error: ", error)
                        completion(nil)
                    }
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

        query.getDocuments { querySnapshot, error in
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
                    } catch {
                        print("ERROR: ", error.localizedDescription)
                    }
                }
                completion(messages, nil)
            }
        }
    }

    func listenToMessageUpdate(roomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        FirestoreEndpoint.chatRoom.colRef
            .document(roomID)
            .collection("Message")
            .order(by: "createdTime", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    completion(nil, error)
                    return
                }

                var messages: [Message] = []

                snapshot.documents.forEach { document in
                    do {
                        let item = try document.data(as: Message.self)
                        messages.append(item)
                    } catch {
                        print("error: ", error)
                        completion(nil, error)
                    }
                }
                completion(messages, nil)
            }
    }

    func listenToChatRoomUpdate(completion: @escaping (([ChatRoom]?, Error?) -> Void)) {
        FirestoreEndpoint.chatRoom.colRef
            .whereField("members", arrayContains: UserDefaults.id)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error getting documents: \(error)")
                    completion(nil, error)
                }

                var chatRooms: [ChatRoom] = []
                if let querySnapshot = querySnapshot {
                    self.fetchUserByID(userID: UserDefaults.id) { user, _ in
                        var blocks = user?.blocks ?? []
                        blocks.append(UserDefaults.id)
                        querySnapshot.documents.forEach { document in
                            do {
                                let item = try document.data(as: ChatRoom.self)
                                let otherUser = item.members.first { $0 != UserDefaults.id }

                                guard
                                    let otherUser = otherUser,
                                    !blocks.contains(otherUser)
                                else {
                                    return
                                }

                                chatRooms.append(item)
                            } catch {
                                print("ERROR: ", error.localizedDescription)
                            }
                        }

                        FirebaseService.shared.fetchRoomMemberData(chatRooms: chatRooms) { chatRooms in
                            completion(chatRooms, nil)
                        }
                    }
                } else {
                    completion(nil, RMError.noData)
                }
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

// MARK: - room
extension FirebaseService {
    func updateRoomInfo(roomID: String, room: Room, completion: @escaping ((Error?) -> Void)) {
        FirestoreEndpoint.room.colRef.document(roomID).delete { [weak self] error in
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
            try docRef.setData(from: room) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
}

// MARK: - Furniture
extension FirebaseService {
    func fetchFurnituresByUserID(userID: String = UserDefaults.id, completion: @escaping (([Furniture]) -> Void)) {
        let query = FirestoreEndpoint.furniture.colRef
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdTime", descending: true)

        getDocuments(query) { (furnitures: [Furniture]) in
            completion(furnitures)
        }
    }

    func insertFurniture(furniture: Furniture, completion: @escaping ((Error?) -> Void)) {
        let docRef = FirestoreEndpoint.furniture.colRef.document()
        var furniture = furniture
        furniture.id = docRef.documentID
        do {
            try docRef.setData(from: furniture)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func updateFurniture(furnitureID: String, furniture: Furniture, completion: @escaping ((Error?) -> Void)) {
        FirestoreEndpoint.furniture.colRef.document(furnitureID).delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else {
                self.insertFurniture(furniture: furniture) { error in
                    completion(error)
                }
            }
        }
    }

    func deleteFurniture(furnitureID: String, completion: @escaping ((Error?) -> Void)) {
        FirestoreEndpoint.furniture.colRef.document(furnitureID).delete { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
}
