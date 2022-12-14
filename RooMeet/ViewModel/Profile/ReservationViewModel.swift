//
//  ReservationViewModel.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/17.
//

import Foundation
import FirebaseFirestore

class ReservationViewModel {
    // MARK: - Properties
    var reservationResults = Observable([Reservation(id: "", createdTime: Timestamp())])
    var userResults = Observable(User(id: UserDefaults.id))

    init() {
        fetchReservations()
    }

    func fetchReservations() {
        FIRRoomService.shared.fetchReservationRoomsByUserID(userID: UserDefaults.id) { [weak self] reservations, user in
            guard let self = self else { return }
            self.userResults.value = user
            self.reservationResults.value = reservations.sorted { rsvnA, rsvnB in
                (rsvnA.requestTime ?? Timestamp()).seconds < (rsvnB.requestTime ?? Timestamp()).seconds
            }
        }
    }
}
