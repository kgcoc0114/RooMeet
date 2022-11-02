//
//  ExploreViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/2.
//

import UIKit
import MapKit

class ExploreViewController: UIViewController {

    @IBOutlet weak var roomExploreMap: MKMapView!

    let loactions = [
        "臺北市中正區新生南路一段90號",
        "臺北市中正區廣州街10號",
        "臺北市中正區延平南路15號",
        "臺北市中正區杭州南路一段1號",
        "臺北市大安區和平東路三段6號",
        "臺北市大安區基隆路三段155巷57號"
    ]

    var geoCodes: [MKPointAnnotation] = []
    
    var locationManger = CLLocationManager()
    
    var postalCode: String?
    var county: String?
    var town: String?

    override func viewDidLoad() {

        super.viewDidLoad()
        print(LocationService.shared.fetchPostalCode(filename: "PostalCode"))
        locationManger.delegate = self
        roomExploreMap.delegate = self

//        locationManger.requestLocation()

        locationManger.requestWhenInUseAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManger.requestLocation()
//        roomExploreMap.showsUserLocation = true
//        let xxx = roomExploreMap.userLocation
//        roomExploreMap.delegate = self
////        LocationService.shared.
//        LocationService.shared.getAddressFromGeoCode(location: roomExploreMap.userLocation.coordinate) { placemark, error in
//            if error != nil {
//                print(error?.localizedDescription)
//            }
//            print(placemark?.country, placemark?.region, placemark?.administrativeArea, placemark?.locality)
//        }
////        loactions.enumerated().forEach { index, location in
////            LocationService.shared.getCoordinates(fullAddress: location) { [self] locationCoordinate in
////                let annotation = MKPointAnnotation()
////                annotation.coordinate = locationCoordinate
////                annotation.title = "room \(index + 1)"
////                geoCodes.append(annotation)
////                show()
////            }
////        }
////
////        LocationService.shared.getCoordinates(handler: { [self] location in
////            let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
////            roomExploreMap.setRegion(region, animated: true)
////        })
    }

    func show() {
        if geoCodes.count == loactions.count {
            DispatchQueue.main.async { [self] in
                roomExploreMap.addAnnotations(geoCodes)
            }
        }
    }
}
extension ExploreViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)

            LocationService.shared.getAddressFromGeoCode(location: location.coordinate) { [weak self] placemark, error in
                if error != nil {
                    print(error?.localizedDescription)
                }
                if let placemark = placemark {
                    self?.postalCode = placemark.postalCode
                    self?.county = placemark.administrativeArea
                    self?.town = placemark.locality
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func setCenterPlace(placemark: CLPlacemark?, error: Error?) {
        if error != nil {
            print(error?.localizedDescription)
        }
        
        if let placemark = placemark {
            postalCode = placemark.postalCode
            county = placemark.administrativeArea
            town = placemark.locality
            print(postalCode, county, town)
        }
    }
}

extension ExploreViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        var center = mapView.centerCoordinate
        LocationService.shared.getAddressFromGeoCode(location: center) { [weak self] placemark, error in
            self?.setCenterPlace(placemark: placemark, error: error)
        }
    }

//    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        print ("Here we are")
//        var center = mapView.centerCoordinate
//        print ("Center is \(center)")
//    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            return nil
//        }
//        var annotationView = mapView.de(
//            withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
//            for: annotation)
        
//        annotationView.markerTintColor = .darkGray
//        if annotationView == nil {
////            annotationView = MKAnnotationView(
////                annotation: annotation,
////                reuseIdentifier: "custom"
////            )
//            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//            let imageView = UIImageView(image: UIImage(systemName: "heart"))
//            imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//            imageView.layer.cornerRadius = 3
//            imageView.clipsToBounds = true
//            annotationView.leftCalloutAccessoryView = imageView
////            annotationView.tintColor = .darkGray
//            let label = UILabel()
//            label.text = annotation.title!
//            annotationView.detailCalloutAccessoryView = label
//
////            annotationView.canShowCallout = true
//        } else {
//            annotationView.annotation = annotation
//        }
//        annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//        let imageView = UIImageView(image: UIImage(systemName: "heart"))
//        imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        imageView.layer.cornerRadius = 3
//        imageView.clipsToBounds = true
//        annotationView.leftCalloutAccessoryView = imageView
//        //            annotationView.tintColor = .darkGray
//        let label = UILabel()
//        label.text = annotation.title!
//        annotationView.detailCalloutAccessoryView = label
//        annotationView.image = UIImage(systemName: "heart")
//        annotationView.clusteringIdentifier = "identifier"
//
//        return annotationView
//    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("select")
    }
}


class RMAnnotation : MKPointAnnotation {
    var room : String?
}
