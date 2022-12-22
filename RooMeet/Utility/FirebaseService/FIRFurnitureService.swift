//
//  FIRFurnitureService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/14.
//

import Foundation

class FIRFurnitureService {
    static let shared = FIRFurnitureService()

    private init(){}

    let firebaseService = FirebaseService.shared

    func fetchFurnituresByUserID(userID: String = UserDefaults.id, completion: @escaping (([Furniture]) -> Void)) {
        let query = FirestoreEndpoint.furniture.colRef
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdTime", descending: true)

        firebaseService.getDocuments(query) { (furnitures: [Furniture]) in
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
