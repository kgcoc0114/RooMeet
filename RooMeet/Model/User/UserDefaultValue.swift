//
//  UserDefaultValue.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/17.
//

import Foundation

@propertyWrapper
struct UserDefaultValue<Value> {
    let userDefault = UserDefaults.standard
    let key: String
    let defaultValue: Value

    var wrappedValue: Value {
        get {
            userDefault.value(forKey: key) as? Value ?? defaultValue
        }

        set {
            userDefault.set(newValue, forKey: key)
        }
    }
}
