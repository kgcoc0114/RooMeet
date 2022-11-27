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

    var locationManger: CLLocationManager = {
        let lm = CLLocationManager()
        lm.requestWhenInUseAuthorization()
        return lm
    }()

    private let scaleX: CLLocationDegrees = 0.01
    private let scaleY: CLLocationDegrees = 0.01

    var postalCodeList: [PostalCode]? = {
        if let url = Bundle.main.url(forResource: "PostalCode", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let jsonData = try JSONDecoder().decode(PostalCodeData.self, from: data)

                return jsonData.data
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }()

    var regionList: [Region]? = {
        if let url = Bundle.main.url(forResource: "Region", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let jsonData = try JSONDecoder().decode(RegionData.self, from: data)

                return jsonData.data
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }()



    // getCoordinates
    func getCoordinates(fullAddress: String = "台北市中正區仁愛路二段99號", handler: @escaping ((CLLocationCoordinate2D) -> Void)) {
        CLGeocoder().geocodeAddressString(fullAddress) { ( placemark, error ) in
            if let error = error {
                print(error)
            }
            if let placemark = placemark {
                handler(placemark.first?.location?.coordinate ?? CLLocationCoordinate2D())
            }
        }
    }
    
    func getAddressFromGeoCode(location: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?, Error?) -> Void) {
        let locale = Locale(identifier: "zh_tw")
        print(location.latitude, location.longitude)

        let loc: CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: locale) { placesmarks, error in
            guard let placemark = placesmarks?.first,
                  error == nil else {
                completion(nil, error)
                return
            }
            completion(placemark, nil)
        }
    }

    func getUserCurrentLocation(completion: @escaping (MKCoordinateSpan?) -> Void) {
        if let currentLocation = locationManger.location?.coordinate {
            completion(MKCoordinateSpan(latitudeDelta: scaleX, longitudeDelta: scaleY))
        }
        completion(nil)
    }

    func fetchPostalCode(filename: String = "PostalCode") -> [PostalCode]? {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let jsonData = try JSONDecoder().decode(PostalCodeData.self, from: data)
                return jsonData.data
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }

    func setCenterRegion(position: CLLocationCoordinate2D, mapView: MKMapView) {
        // set current location in map
        let region = MKCoordinateRegion(
            center: position,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        mapView.setRegion(region, animated: true)
    }
}

