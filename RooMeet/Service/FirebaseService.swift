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

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum RMError: String, Error {
    case noData = "沒有資料"
    case responseError = ""
    case signOutError = "登出失敗"
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
                let chatRoom = roomResult
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
        print("blocks = ", blocks)

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
            let sorted = rooms.sorted { $0.createdTime.seconds > $1.createdTime.seconds }
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
                        rooms.append(room)
                        group.leave()
                    }
                case .failure(_):
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

            rsvns = rsvns.sorted { rsvnA, rsvnB in
                guard let requestTimeA = rsvnA.requestTime,
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

    func fetchRoomByRoomID(roomID: String, user: User, completion: @escaping ((Room) -> Void)) {
        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)

        let query = FirestoreEndpoint.room.colRef
            .whereField("roomID", isEqualTo: roomID)
            .whereField("isDeleted", isEqualTo: false)

        getDocuments(query) { (rooms: [Room]) in
            rooms.forEach { room in
                var room = room
                if !blocks.contains(room.userID) {
                    self.fetchUserByID(userID: room.userID) { user, _ in
                        room.userData = user
                        completion(room)
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

        batchDeleteReservation(query: senderRef) { result in
            group.leave()
        }


        // get receiver user's reservations
        group.enter()
        let receiverRef = FirestoreEndpoint.reservation.colRef.whereField("receiver", isEqualTo: userID)
        batchDeleteReservation(query: receiverRef) { result in
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
