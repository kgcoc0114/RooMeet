//
//  FirebasePostService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/28.
//

import Foundation

extension FirebaseService {
    func deletePost(roomID: String) {
        let docRef = FirestoreEndpoint.room.colRef.document(roomID)

        docRef.updateData(["isDeleted": true])
    }
}
