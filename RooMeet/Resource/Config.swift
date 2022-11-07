//
//  Config.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/7.
//

import Foundation

fileprivate let defaultIceServers = [
    "stun:stun1.l.google.com:19302",
    "stun:stun2.l.google.com:19302"
]

struct Config {
    let webRTCIceServers: [String]
    static let `default` = Config(webRTCIceServers: defaultIceServers)
}
