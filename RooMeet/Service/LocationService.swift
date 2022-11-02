//
//  LocationService.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import Foundation
import MapKit

class LocationService {
    static let shared = LocationService()
    
    func getCoordinates(fullAddress: String = "台北市中正區仁愛路二段99號", handler: @escaping ((CLLocationCoordinate2D) -> Void)) {
        CLGeocoder().geocodeAddressString(fullAddress) { ( placemark, error ) in
            handler(placemark?.first?.location?.coordinate ?? CLLocationCoordinate2D())
        }
    }
}
