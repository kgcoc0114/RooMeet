//
//  RooMeetTests.swift
//  RooMeetTests
//
//  Created by kgcoc on 2022/12/8.
//

import XCTest
@testable import RooMeet

class RooMeetTests: XCTestCase {
    var postVCSut: PostViewController!
    var roomDetailVCSut: RoomDetailViewController!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        postVCSut = PostViewController(entryType: .new, data: nil)
        roomDetailVCSut = RoomDetailViewController(
            room: Room(
                roomID: "1234",
                userID: UserDefaults.id,
                userData: User(id: UserDefaults.id),
                createdTime: FirebaseService.shared.currentTimestamp,
                modifiedTime: FirebaseService.shared.currentTimestamp,
                title: "分租套房", roomImages: [], rooms: [], roomFeatures: [],
                roomPetsRules: [], roomHighLights: [], roomGenderRules: [],
                roomCookingRules: [], roomElevatorRules: [], roomBathroomRules: [],
                town: "中山區", county: "臺北市", address: "", lat: nil, long: nil,
                postalCode: nil, billInfo: nil, leaseMonth: 0, room: 0, parlor: 0,
                movinDate: Date(), otherDescriction: "", isDeleted: false, roomMinPrice: nil),
            user: User(id: UserDefaults.id)
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        postVCSut = nil
        roomDetailVCSut = nil
        try super.tearDownWithError()
    }

    func testPostVCRequiredField() {
        // given
        postVCSut.postBasicData = PostBasicData()

        // when
        let canSave = postVCSut.canSave()

        // then
        XCTAssertEqual(canSave, false, "Add Room Page required field: error")
    }

    func testRoomDetailVCSendRequest() {
        // given
        roomDetailVCSut.selectedDate = nil

        // when
        let reservationError = roomDetailVCSut.canSendRequest()

        // then
        XCTAssertEqual(reservationError != nil, true, "roomDetailVC canSendRequest func: error")
    }

    func testRoomMinPrice() {
        // given
        let room = Room(
            userID: UserDefaults.id,
            createdTime: FirebaseService.shared.currentTimestamp,
            modifiedTime: FirebaseService.shared.currentTimestamp,
            title: "",
            roomImages: [],
            rooms: [RoomSpec(roomType: "雅房", price: 12000, space: 12), RoomSpec(roomType: "雅房", price: 8000, space: 8)],
            roomFeatures: [],
            roomPetsRules: [],
            roomHighLights: [],
            roomGenderRules: [],
            roomCookingRules: [],
            roomElevatorRules: [],
            roomBathroomRules: [],
            town: "中山區",
            county: "臺北市",
            address: "",
            leaseMonth: 0,
            room: 0,
            parlor: 0,
            movinDate: Date()
        )
        // when
        let min = room.getRoomMinPrice() ?? 0
        // then
        XCTAssertEqual(min, 8000, "room min price: error")
    }
}
