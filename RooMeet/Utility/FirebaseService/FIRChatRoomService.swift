//
//  FIRChatRoomService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/14.
//
import Foundation

class FIRChatRoomService {
    static let shared = FIRChatRoomService()

    let firebaseService = FirebaseService.shared

    // MARK: - Chat Room
    func fetchChatRoomsByUserID(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
        let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", arrayContains: UserDefaults.id)

        firebaseService.getDocuments(query) { (chatRooms: [ChatRoom]) in
            completion(chatRooms)
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
                    self.firebaseService.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
                        guard let self = self else { return }

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

                        self.fetchRoomMemberData(chatRooms: chatRooms) { chatRooms in
                            completion(chatRooms, nil)
                        }
                    }
                } else {
                    completion(nil, RMError.noData)
                }
            }
    }

    func listenToMessageUpdate(chatRoomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        FirestoreEndpoint.message(chatRoomID).colRef
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

    func getChatRoomByMembers(members: [String], completion: @escaping ((Result<ChatRoom>) -> Void)) {
        if members.count == 2 {
            let query = FirestoreEndpoint.chatRoom.colRef.whereField("members", arrayContains: members[0])

            firebaseService.getDocuments(query) { [weak self] (chatRooms: [ChatRoom]) in
                guard let self = self else { return }
                var chatRooms = chatRooms
                chatRooms = chatRooms.filter { $0.members.contains(members[1]) }

                if chatRooms.isEmpty {
                    self.insertNewChatRoom(members: members) { chatRoom, _ in
                        if let chatRoom = chatRoom {
                            self.fetchRoomMemberData(chatRooms: [chatRoom]) { chatRooms in
                                if let returnChatRoom = chatRooms.first {
                                    completion(Result.success(returnChatRoom))
                                }
                            }
                        }
                    }
                } else {
                    self.fetchRoomMemberData(chatRooms: chatRooms) { chatRooms in
                        if let returnChatRoom = chatRooms.first {
                            completion(Result.success(returnChatRoom))
                        }
                    }
                }
            }
        } else {
            completion(Result.failure(RMError.parameterError))
        }
    }

    func fetchChatRoomDataWithMemberData(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
        fetchChatRoomsByUserID(userID: userID) { [weak self] roomsResult in
            guard let self = self else { return }
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
                    self.firebaseService.fetchUserByID(userID: memberID, index: index) { user, index in
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

    func fetchRoomMemberData(chatRooms: [ChatRoom], completion: @escaping (([ChatRoom]) -> Void)) {
        let group = DispatchGroup()
        var chatRooms = chatRooms
        chatRooms.enumerated().forEach { index, roomResult in
            let chatRoom = roomResult
            let members = chatRoom.members.filter { member in
                member != UserDefaults.id
            }

            if !members.isEmpty {
                let memberID = members[0]
                group.enter()
                self.firebaseService.fetchUserByID(userID: memberID, index: index) { user, index in
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

    func insertNewChatRoom(members: [String], completion: @escaping ((ChatRoom?, Error?) -> Void)) {
        let colRef = FirestoreEndpoint.chatRoom.colRef
        let docRef = colRef.document()
        let chatroom = ChatRoom(
            id: docRef.documentID,
            members: members,
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
}
