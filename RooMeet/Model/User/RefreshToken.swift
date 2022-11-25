//
//  RefreshToken.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/24.
//

struct RefreshTokenBody: Encodable {
    let clientID: String
    let clientSecret: String
    let code: String
    let grantType: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case code
        case grantType = "grant_type"
    }
}

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}
