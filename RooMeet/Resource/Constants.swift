//
//  Constants.swift
//  RooMeet
//
//  Created by kgcoc on 2022/10/29.
//

import Foundation
import MapKit

struct BillConstant {
    static let shared = BillConstant()
    let cancal = "取消"
    let submit = "確認"
}

var gCurrentUser = User.mockUser

var gCurrentPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 25.03320617048529, longitude: 121.56449873729362)

var gDefaultCounty = "台北市"

var avatarHeight: CGFloat = 30
