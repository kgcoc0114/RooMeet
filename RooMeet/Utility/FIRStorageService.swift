//
//  FIRStorageService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/1.
//

import Foundation
import UIKit
import FirebaseStorage

enum FIRStorageEndpoint {
    case chatImages
    case furnitureImages
    case profile
    case roomImages

    var path: String {
        switch self {
        case .profile:
            return "Profile"
        case .chatImages:
            return "ChatImages"
        case .furnitureImages:
            return "FurnitureImages"
        case .roomImages:
            return "RoomImages"
        }
    }
}

class FIRStorageService {
    static let shared = FIRStorageService()

    private init(){}

    func uploadImage(image: UIImage, path: String, completion: @escaping (URL?, Error?) -> Void) {
        var uploadData: Data?

        let uniqueString = NSUUID().uuidString

        let imageSize = image.getSizeIn(.kilobyte)
        if imageSize > RMConstants.shared.compressSizeGap {
            let factor = RMConstants.shared.compressSizeGap / imageSize
            uploadData = image.jpegData(compressionQuality: factor)
        } else {
            uploadData = image.pngData()
        }

        let storageRef = Storage.storage().reference(withPath: path).child("\(uniqueString).png")

        if let uploadData = uploadData {
            storageRef.putData(uploadData) { _, error in
                if let error = error {
                    debugPrint("Error: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                storageRef.downloadURL { url, _ in
                    guard let downloadURL = url else {
                        return
                    }
                    completion(downloadURL, nil)
                }
            }
        } else {
            completion(nil, RMError.noData)
        }
    }
}
