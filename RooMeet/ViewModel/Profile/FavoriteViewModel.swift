//
//  FavoriteViewModel.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/17.
//

import Foundation
import Combine

class FavoriteViewModel {
    @Published var rooms: [Room] = []
    @Published var user = User(id: UserDefaults.id)
    @Published var favoriteRooms: [FavoriteRoom] = []

    func fetchRooms(entryPage: EntryPage) {
        FirebaseService.shared.fetchUserByID(userID: UserDefaults.id) { [weak self] user, _ in
            guard let self = self else { return }
            self.user = user ?? User(id: UserDefaults.id)
        }

        if entryPage == .fav {
            FIRRoomService.shared.fetchFavoriteRoomsByUserID(userID: UserDefaults.id) { [weak self] rooms, favoriteRooms in
                guard let self = self else { return }
                self.rooms = rooms
                self.favoriteRooms = favoriteRooms
            }
        } else {
            FIRRoomService.shared.fetchRoomsByUserID(userID: UserDefaults.id) { [weak self] rooms in
                guard let self = self else { return }
                self.rooms = rooms
            }
        }
    }

    func updateUserFavRoomsData(shouldUpdate: Bool) {
        if shouldUpdate {
            FirebaseService.shared.updateUserFavoriteRoomsData(favoriteRooms: favoriteRooms)
        }
    }
}
