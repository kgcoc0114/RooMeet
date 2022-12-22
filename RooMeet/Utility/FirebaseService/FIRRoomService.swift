//
//  FIRRoomService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/14.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

// MARK: - room
class FIRRoomService {
    static let shared = FIRRoomService()

    let firebaseService = FirebaseService.shared

    private init(){}

    func fetchRoomsByUserID(userID: String, completion: @escaping (([Room]) -> Void)) {
        let query = FirestoreEndpoint.room.colRef
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdTime", descending: true)

        let group = DispatchGroup()
        firebaseService.getDocuments(query) { (rooms: [Room]) in
            var rooms = rooms
            rooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                group.enter()
                self.firebaseService.fetchUserByID(userID: ownerID, index: index) { user, index in
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

    func fetchRoomDataByQuery(user: User, query: Query, completion: @escaping (([Room]) -> Void)) {
        var blocks = user.blocks ?? []
        blocks.append(UserDefaults.id)
        print(blocks)

        let group = DispatchGroup()
        var rooms: [Room] = []
        var users: [User] = []

        group.enter()
        firebaseService.getDocuments(query) { (tmpRooms: [Room]) in
            rooms += tmpRooms
            print("rooms.count = ", rooms.count)
            tmpRooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                if !blocks.contains(ownerID) {
                    group.enter()
                    self.firebaseService.fetchUserByID(userID: ownerID, index: index) { user, _ in
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
        firebaseService.getDocuments(queryNil) { (tmpRooms: [Room]) in
            rooms += tmpRooms
            print("rooms.count = ", rooms.count)
            tmpRooms.enumerated().forEach { index, roomResult in
                let ownerID = roomResult.userID
                if !blocks.contains(ownerID) {
                    group.enter()
                    self.firebaseService.fetchUserByID(userID: ownerID, index: index) { user, _ in
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

                        self.firebaseService.fetchUserByID(userID: item.userID) { user, _ in
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

    func fetchRoomsByReservationID(user: User, completion: @escaping (([Reservation]) -> Void)) {
        var reservations: [Reservation] = []
        var rooms: [Room] = []
        let group = DispatchGroup()
        user.reservations.forEach { reservationID in
            group.enter()
            firebaseService.fetchReservationByID(reservationID: reservationID) { [weak self] result in
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
                case .failure:
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

    // MARK: - Explore Page
    func fetchRoomByCoordinate(
        northWest: CLLocationCoordinate2D,
        southEast: CLLocationCoordinate2D,
        userBlocks: [String] = [],
        completion: @escaping (([Room]?) -> Void)
    ) {
        var userBlocks = userBlocks
        userBlocks.append(UserDefaults.id)

        let query = FirestoreEndpoint.room.colRef
            .whereField("lat", isLessThanOrEqualTo: northWest.latitude)
            .whereField("lat", isGreaterThanOrEqualTo: southEast.latitude)
            .whereField("isDeleted", isEqualTo: false)

        firebaseService.getDocuments(query) { (rooms: [Room]) in
            var roomsWithoutOwnerData: [Room] = []
            let group = DispatchGroup()

            for var room in rooms {
                let ownerID = room.userID

                if let long = room.long {
                    if long >= northWest.longitude
                        && long <= southEast.longitude
                        && !userBlocks.contains(ownerID) {
                        group.enter()
                        self.firebaseService.fetchUserByID(userID: ownerID, index: nil) { user, _ in
                            room.userData = user
                            roomsWithoutOwnerData.append(room)
                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: DispatchQueue.main) {
                completion(roomsWithoutOwnerData)
            }
        }
    }

    func fetchFavoriteRoomsByRoomID(user: User, completion: @escaping (([Room]) -> Void)) {
        var rooms: [Room] = []

        let group = DispatchGroup()
        print(user.favoriteRoomIDs)
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

    func fetchReservationRoomsByUserID(userID: String, completion: @escaping (([Reservation], User) -> Void)) {
        firebaseService.fetchUserByID(userID: userID) { [weak self] user, _ in
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

    func fetchFavoriteRoomsByUserID(userID: String, completion: @escaping (([Room], [FavoriteRoom]) -> Void)) {
        firebaseService.fetchUserByID(userID: userID) { [weak self] user, _ in
            guard let self = self, let user = user else {
                completion([], [])
                return
            }
            self.fetchFavoriteRoomsByRoomID(user: user) { rooms in
                completion(rooms, user.favoriteRooms)
            }
        }
    }

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
            query = FirestoreEndpoint.room.colRef.whereField("isDeleted", isEqualTo: false)
        }

        query = query.order(by: "userID", descending: true)

        let group = DispatchGroup()
        firebaseService.getDocuments(query) { [weak self] (rooms: [Room]) in
            guard let self = self else { return }

            var results: [Room] = []

            for var room in rooms {
                let ownerID = room.userID
                group.enter()
                if !blocks.contains(ownerID) {
                    self.firebaseService.fetchUserByID(userID: ownerID, index: nil) { user, _ in
                        room.userData = user
                        results.append(room)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: DispatchQueue.main) {
                let filterRooms = results.filter { $0.userData != nil }

                let sortedRooms = filterRooms.sorted { roomA, roomB in
                    roomA.createdTime.seconds > roomB.createdTime.seconds
                }
                completion(sortedRooms)
            }
        }
    }

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

    func deletePost(roomID: String) {
        let docRef = FirestoreEndpoint.room.colRef.document(roomID)

        docRef.updateData(["isDeleted": true])
    }
}
