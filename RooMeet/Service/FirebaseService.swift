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

class FirebaseService {
    static let shared = FirebaseService()

    let database = Firestore.firestore()

    func fetchRoomByArea(postalCode: String, completion: @escaping (([Room]?) -> Void)) {
        database.collection("Room").whereField("postalCode", isEqualTo: postalCode).getDocuments() {
            (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                }

                var rooms: [Room] = []
                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: Room.self)
                            rooms.append(item)
                        } catch {
                            print("DEBUG: Error decoding \(Room.self) data -", error.localizedDescription)
                        }
                    }
                    completion(rooms)
                }
        }
    }
    
    
    func fetchUserByID(userID: String, index: Int? = nil, completion: @escaping ((User?, Int?) -> Void)) {
        let docRef = database.collection("User").document(userID)
        
        docRef.getDocument { document, error in
            print(document, error)
            if let document = document, document.exists {
                do {
                    let item = try document.data(as: User.self)
                    completion(item, index)
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
                }
            } else {
                completion(nil, index)
            }
        }
    }
    
    func fetchChatRoomsByUserID(userID: String, completion: @escaping (([ChatRoom]) -> Void)) {
//        .collection("ChatRoom")
//        .where("members", "array-contains", "LNC9Lmn7s8LrvLOoymKv")
        database.collection("ChatRoom").whereField("members", arrayContains: "LNC9Lmn7s8LrvLOoymKv").getDocuments {
            (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
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
                    } catch let DecodingError.typeMismatch(type, context)  {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("error: ", error)
                    }
                    
//                    catch {
//                        print("DEBUG: Error decoding \(ChatRoom.self) data -", error.localizedDescription)
//                    }
                }
                completion(chatRooms)
            }
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

    func fetchRoomByCoordinate(
        northWest: CLLocationCoordinate2D,
        southEast: CLLocationCoordinate2D,
        completion: @escaping (([Room]?) -> Void)
    ) {
        database.collection("Room")
            .whereField("lat", isLessThanOrEqualTo: northWest.latitude)
            .whereField("lat", isGreaterThanOrEqualTo: southEast.latitude).getDocuments() {
                (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
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
//
    func fetchMessagesbyRoomID(roomID: String, completion: @escaping (([Message]?, Error?) -> Void)) {
        print("===", roomID)
        let ref = database.collection("ChatRoom").document(roomID).collection("Message").getDocuments(completion: { querySnapshot, error in
            if let error = error {
                completion(nil, error)
                print("Error getting documents: \(error)")
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
                    } catch let DecodingError.typeMismatch(type, context)  {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("error: ", error)
                    }
                    //                        catch {
                    //                            print("DEBUG: Error decoding \(Room.self) data -", error.localizedDescription)
                    //                            completion(nil, error)
                    //                        }
                }
                completion(messages, nil)
            }
        })
    }
}

