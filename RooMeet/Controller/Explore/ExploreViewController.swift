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

    lazy var centerButton: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.backgroundColor = .white
        button.tintColor = UIColor.darkGray
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.layer.cornerRadius = RMConstants.shared.mapCenterButtonWidth / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(setMapCenter(_:)), for: .touchUpInside)
        return button
    }()

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
                }
            }
            show()
        }
    }

    @IBOutlet weak var resetFilterButton: UIButton! {
        didSet {
            resetFilterButton.setTitle("", for: .normal)
            resetFilterButton.setImage(UIImage.asset(.broom), for: .normal)
            resetFilterButton.backgroundColor = .white
            resetFilterButton.tintColor = UIColor.darkGray
            resetFilterButton.titleLabel?.font = UIFont.regularText()
            resetFilterButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        }
    }

    var isFilter = false

    var geoCodes: [RMAnnotation] = []
    var geoCodesAddList: [RMAnnotation] = []
    var geoCodesRemoveList: [RMAnnotation] = []
    var prevGeoCodes: [RMAnnotation] = []

    var locationManger = CLLocationManager()

    var postalCode: String?
    var currentPostalCode: Int?

    var user: User?
    var county: String?
    var town: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Explore"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.settings_sliders),
            style: .plain,
            target: self,
            action: #selector(showFilterPage))

        roomExploreMap.delegate = self

        view.addSubview(centerButton)

        locationManger.requestWhenInUseAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManger.requestLocation()

        roomExploreMap.showsUserLocation = true

        fetchRooms()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchRooms()

        LocationService.shared.setCenterRegion(position: RMConstants.shared.currentPosition, mapView: roomExploreMap)
    }

    override func viewDidLayoutSubviews() {
        NSLayoutConstraint.activate([
            centerButton.widthAnchor.constraint(equalToConstant: RMConstants.shared.mapCenterButtonWidth),
            centerButton.heightAnchor.constraint(equalTo: centerButton.widthAnchor),
            centerButton.bottomAnchor.constraint(equalTo: roomExploreMap.bottomAnchor, constant: -10),
            centerButton.trailingAnchor.constraint(equalTo: roomExploreMap.trailingAnchor, constant: -10)
        ])
        resetFilterButton.layer.cornerRadius = resetFilterButton.bounds.width / 2
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let all = roomExploreMap.annotations
        roomExploreMap.removeAnnotations(all)
    }

    private func show() {
        DispatchQueue.main.async { [self] in
            roomExploreMap.removeAnnotations(roomExploreMap.annotations)
            roomExploreMap.addAnnotations(geoCodes)
        }
    }

    private func fetchRooms() {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else {
                return
            }

            self.user = user
            self.getRoomForCurrentPosition(mapView: self.roomExploreMap)
        }
    }

    @objc private func showFilterPage() {
        guard let user = user else {
            return
        }

        guard let filterVC = UIStoryboard.home.instantiateViewController(
            withIdentifier: FilterViewController.self) as? FilterViewController else {
            print("ERROR: FilterViewController Error")
            return
        }

        filterVC.blockUserIDs = user.blocks ?? []

        filterVC.completion = { query in
            FIRRoomService.shared.fetchRoomDataByQuery(user: user, query: query) { rooms in
                self.rooms = rooms
            }
            self.isFilter = true
        }
        filterVC.modalPresentationStyle = .overCurrentContext
        present(filterVC, animated: false)
    }

    @objc private func setMapCenter(_ sender: Any) {
        LocationService.shared.setCenterRegion(position: RMConstants.shared.currentPosition, mapView: roomExploreMap)
    }

    @IBAction func resetFilterAction(_ sender: Any) {
        isFilter = false
        getRoomForCurrentPosition(mapView: roomExploreMap)
    }
}

extension ExploreViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if user != nil {
                getRoomForCurrentPosition(mapView: roomExploreMap)
            }
            LocationService.shared.setCenterRegion(position: location.coordinate, mapView: roomExploreMap)
        }
    }

    private func getRoomForCurrentPosition(mapView: MKMapView) {
        let northWestCoordinate = mapView.convert(CGPoint(x: 0, y: 0), toCoordinateFrom: mapView)
        let southEastCoordinate = mapView.convert(
            CGPoint(x: mapView.frame.size.width, y: mapView.frame.size.height),
            toCoordinateFrom: mapView
        )

        if !isFilter {
            FIRRoomService.shared.fetchRoomByCoordinate(
                northWest: northWestCoordinate,
                southEast: southEastCoordinate,
                userBlocks: user?.blocks ?? []
            ) { [weak self] rooms in
                guard
                    let self = self,
                    let rooms = rooms else {
                    print("ERROR: fetch rooms error.")
                    return
                }
                self.rooms = rooms
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension ExploreViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if user != nil {
            getRoomForCurrentPosition(mapView: roomExploreMap)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let roomMarker = view.annotation as? RMAnnotation,
        let room = roomMarker.room else {
            return
        }
        let detailViewController = RoomDetailViewController(room: room, user: user)
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
