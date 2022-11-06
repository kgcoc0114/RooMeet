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

    var rooms: [Room] = [] {
        didSet {
            if rooms.isEmpty {
                roomExploreMap.removeAnnotations(geoCodes)
            }

            prevGeoCodes = geoCodes
            geoCodes.removeAll()
            rooms.forEach { room in
                if
                    let lat = room.lat,
                    let long = room.long {
                    let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    let annotation = RMAnnotation()
                    annotation.coordinate = location
                    annotation.room = room
                    geoCodes.append(annotation)
                    show()
                }
            }
        }
    }

    var geoCodes: [RMAnnotation] = []
    var geoCodesAddList: [RMAnnotation] = []
    var geoCodesRemoveList: [RMAnnotation] = []
    var prevGeoCodes: [RMAnnotation] = []

    var locationManger = CLLocationManager()

    var postalCode: String?
    var currentPostalCode: Int?

    var county: String?
    var town: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // set title
        navigationItem.title = "Explore"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(showFilterPage))

        roomExploreMap.delegate = self

        locationManger.requestWhenInUseAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        // get user current location
        locationManger.requestLocation()
        roomExploreMap.showsUserLocation = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocationService.shared.setCenterRegion(position: gCurrentPosition, mapView: roomExploreMap)
        getRoomForCurrentPosition(mapView: roomExploreMap)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let all = roomExploreMap.annotations
        roomExploreMap.removeAnnotations(all)
    }

    func show() {
        if geoCodes.count == rooms.count {
            DispatchQueue.main.async { [self] in
                roomExploreMap.removeAnnotations(prevGeoCodes)
                roomExploreMap.addAnnotations(geoCodes)
            }
        }
    }

    // FIXME: 條件與滑動經緯度同時成立
    @objc private func showFilterPage() {
        guard let filterVC = UIStoryboard.home.instantiateViewController(
            withIdentifier: "FilterViewController") as? FilterViewController else {
            print("ERROR: FilterViewController Error")
            return
        }
        filterVC.completion = { query in
            FirebaseService.shared.fetchRoomDatabyQuery(query: query) { rooms in
                self.rooms = rooms
            }
        }
        present(filterVC, animated: true)
    }
}

extension ExploreViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            getRoomForCurrentPosition(mapView: roomExploreMap)
            LocationService.shared.setCenterRegion(position: location.coordinate, mapView: roomExploreMap)
        }
    }

    private func getRoomForCurrentPosition(mapView: MKMapView) {
        let northWestCoordinate = mapView.convert(CGPoint(x: 0, y: 0), toCoordinateFrom: mapView)
        let southEastCoordinate = mapView.convert(
            CGPoint(x: mapView.frame.size.width, y: mapView.frame.size.height),
            toCoordinateFrom: mapView
        )

        FirebaseService.shared.fetchRoomByCoordinate(
            northWest: northWestCoordinate,
            southEast: southEastCoordinate
        ) { [weak self] rooms in
            guard let rooms = rooms else {
                print("ERROR: fetch rooms error.")
                return
            }
            self?.rooms = rooms
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension ExploreViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        getRoomForCurrentPosition(mapView: mapView)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let roomMarker = view.annotation as? RMAnnotation,
        let room = roomMarker.room else {
            return
        }
        let detailViewController = RoomDetailViewController(room: room)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
            for: annotation)

        annotationView.clusteringIdentifier = "identifier"
        return annotationView
    }
}

class RMAnnotation: MKPointAnnotation {
    var room: Room?
}
