//
//  SwiftJWTWrapper.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/24.
//

import SwiftJWT

struct RMClaims: Claims {
    let iss: String
    let sub: String
    let exp: Date
    let aud: String
}
