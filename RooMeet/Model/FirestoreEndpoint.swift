//
//  FirestoreEndpoint.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/27.
//


enum Result<T> {
    case success(T)
    case failure(Error)
}

enum RMError: String, Error {
    case noData = "沒有資料"
    case responseError = ""
    case signOutError = "登出失敗"
}
