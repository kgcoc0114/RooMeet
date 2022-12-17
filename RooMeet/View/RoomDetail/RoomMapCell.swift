//
//  RoomMapCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/12.
//

import UIKit
import MapKit

class RoomMapCell: UICollectionViewCell {
    private var location: CLLocationCoordinate2D?

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.layer.cornerRadius = RMConstants.shared.messageCornerRadius
        }
    }

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

    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(centerButton)
    }

    override func layoutSubviews() {
        NSLayoutConstraint.activate([
            centerButton.widthAnchor.constraint(equalToConstant: RMConstants.shared.mapCenterButtonWidth),
            centerButton.heightAnchor.constraint(equalTo: centerButton.widthAnchor),
            centerButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -10),
            centerButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10)
        ])
    }

    func configureCell(latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.location = location
        LocationService.shared.setCenterRegion(position: location, mapView: mapView)

        let annotation = RMAnnotation()
        annotation.coordinate = location
        DispatchQueue.main.async { [self] in
            mapView.addAnnotation(annotation)
        }
    }

    @objc func setMapCenter(_ sender: Any) {
        guard let location = location else {
            return
        }
        mapView.setCenter(location, animated: true)
    }
}

extension RoomMapCell: RoomDetailCell {
    func configure(container: RoomDetailContainer) {
        guard
            let room = (container as? RoomContainer)?.room,
            let latitude = room.lat,
            let longitude = room.long
        else {
            return
        }

        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.location = location
        LocationService.shared.setCenterRegion(position: location, mapView: mapView)

        let annotation = RMAnnotation()
        annotation.coordinate = location
        DispatchQueue.main.async { [self] in
            mapView.addAnnotation(annotation)
        }
    }
}
