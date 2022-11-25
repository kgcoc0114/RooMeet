//
//  KeyChainService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/24.
//

import Security
import KeychainAccess

class KeyChainService {
    static let shared = KeyChainService()

    private let service: Keychain

    private let serverTokenKey: String = "RooMeetRefreshToken"

    private init() {
        service = Keychain(service: Bundle.main.bundleIdentifier!)
    }

    var refreshToken: String? {
        set {
            guard let uuid = UserDefaults.standard.value(forKey: serverTokenKey) as? String else {
                let uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: serverTokenKey)
                service[uuid] = newValue
                return
            }

            service[uuid] = newValue
        }

        get {
            guard let serverKey = UserDefaults.standard.string(forKey: serverTokenKey) else { return nil }
            for item in service.allItems() {
                if let key = item["key"] as? String,
                   key == serverKey {
                    return item["value"] as? String
                }
            }

            return nil
        }
    }
}
