//
//  CallViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/7.
//

import UIKit
import WebRTC
import FirebaseFirestore
import FirebaseFirestoreSwift

class CallViewController: UIViewController {
    // for webRTC
    private let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
    private var hasLocalSdp: Bool = false
    var state: RTCIceConnectionState?

    var chatRoom: ChatRoom?
    var otherUserData: ChatMember?
    var currentUserData: ChatMember?

    var callRoomId: String?
    var callerData: ChatMember?
    var calleeData: ChatMember?

    var callType: CallType = .offer // offer: 自己主動播 answer: 對方播
    var roomId: String?

    var startTime: Timestamp?
    var endTime: Timestamp?
    var callTime: String?
    var callStatus: String?
    var completion: ((Message) -> Void)?

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var answerButton: UIButton!
    @IBOutlet weak var hangUpButton: UIButton!
    @IBOutlet weak var callTimeLabel: UILabel! {
        didSet {
            callTimeLabel.isHidden = true
        }
    }

    private var listener: ListenerRegistration?

    init(callRoomId: String, callType: CallType, callerData: ChatMember, calleeData: ChatMember) {
        super.init(nibName: "CallViewController", bundle: nil)

        self.callRoomId = callRoomId
        self.callType = callType
        self.callerData = callerData
        self.calleeData = calleeData

        if callerData.id != gCurrentUser.id {
            otherUserData = callerData
        } else {
            otherUserData = calleeData
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webRTCClient.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUp()
        listenCall()
    }

    func setUp() {
        switch callType {
        case .offer:
            statusLabel.text = "wait for ..."
            offerDidTap()
        case .answer:
            print("需要接電話")
        }
    }

    func listenCall() {
        Firestore.firestore().collection("Call").document(callRoomId!)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
//                    self?.dismiss(animated: true)
                    return
                }
                do {
                    let call = try document.data(as: Call.self)
                    print("====", call.status)
                    var status: String
                    self?.callStatus = call.status
                    switch call.status {
                    case "close":
                        status = "結束通話"
                        self?.callTimeLabel.isHidden = false
                        self?.answerButton.isHidden = true

                    case "answer":
                        self?.startTime = call.startTime
                        self?.callTimeLabel.isHidden = false
                        self?.hangUpButton.isHidden = false
                        self?.answerButton.isHidden = true
                        status = "開始通話中"

                    case "offer":
                        self?.startTime = call.startTime
                        if call.caller == gCurrentUser.id {
                            status = "等待\(self?.otherUserData!.name)回覆中"
                            self?.hangUpButton.isHidden = false
                            self?.answerButton.isHidden = true

                        } else {
                            status = "\(self?.otherUserData!.name)\n打電話給你"
                            self?.hangUpButton.isHidden = false
                            self?.answerButton.isHidden = false
                        }
                    case "cancel":
                        status = ""
                        self?.dismiss(animated: true)
                    default:
                        status = ""
                    }
                    DispatchQueue.main.async {
                        self?.statusLabel.text = status
                        self?.callTimeLabel.text = "通話時間: \(call.callTime)"
                    }
                } catch let DecodingError.dataCorrupted(context) {
                    print(context)
                } catch let DecodingError.keyNotFound(key, context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.valueNotFound(value, context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.typeMismatch(type, context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print("error: ", error)
                }
            }
    }

    private func dealWithHangUp() {
//        guard
//            let callRoomId = self.callRoomId,
//            let callerData = self.callerData
//        else { return }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.webRTCClient.closeConnection()
        }

        endTime = Timestamp()
        guard
            let sTime = startTime,
            let eTime = endTime else {
            return
        }
        callTime = DateFormatter.shared.getTimeIntervalString(startTimestamp: sTime, endTimestamp: eTime)
        print(callTime)
        updateCallData(status: "close", content: callTime ?? "")
    }

    @IBAction func answer(_ sender: Any) {
        joinARoom()
    }

    @IBAction func hangUp(_ sender: Any) {
        guard
            let callRoomId = self.callRoomId,
            let callerData = self.callerData
        else { return }

        if state == .closed || state == .failed {
            print("被掛電話")
        } else {
            // 自播自己取消
            if callStatus == "offer" && callType == .offer {
                print("======== 自播自己取消")
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.webRTCClient.closeConnection()
                }

                updateCallData(status: "cancel", content: "通話已取消")

                dismiss(animated: true)

                // 掛對方來電
            } else if callStatus == "offer" && callType == .answer {
                print("======== 掛對方來電")
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.webRTCClient.closeConnection()
                }

                updateCallData(status: "cancel", content: "通話已取消")

                dismiss(animated: true)
            } else {
                // 正常通話結束
                if callStatus != "close" {
                    dealWithHangUp()
                }
                dismiss(animated: true)
            }
        }
    }

    func updateCallData(status: String, content: String) {
        guard
            let callRoomId = self.callRoomId,
            let callerData = self.callerData
        else { return }

        let docRef = Firestore.firestore().collection("Call").document(callRoomId)
        var updateData: [AnyHashable : Any]
        if status == "close" {
            updateData = [
                "status": status,
                "endTime": endTime as Any,
                "callTime": callTime as Any
            ]
        } else {
            updateData = [
                "status": status,
                "endTime": endTime as Any
            ]
        }
        docRef.updateData(updateData)

        let messageRef = Firestore.firestore()
            .collection("ChatRoom")
            .document(callRoomId)
            .collection("Message")
            .document()

        let message = Message(
            id: messageRef.documentID,
            messageType: MessageType.call.rawValue,
            sendBy: callerData.id,
            content: content,
            createdTime: Timestamp()
        )

        do {
            try messageRef.setData(from: message)
        } catch let error {
            print("Error writing Message to Firestore: \(error)")
        }

        let chatRoomRef = Firestore.firestore().collection("ChatRoom").document(callRoomId)
        let lastMessage = LastMessage(
            id: messageRef.documentID,
            content: status == "close" ? "通話時間 \(content)" : content,
            createdTime: message.createdTime
        )

        chatRoomRef.updateData([
            "lastMessage": lastMessage.toDict,
            "lastUpdated": lastMessage.createdTime
        ])
    }

    func delete() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        Firestore.firestore().collection("Call").document(callRoomId).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
}

// MARK: - webRTC
extension CallViewController {
    // MARK: - create phone call
    private func offerDidTap() {
        DispatchQueue.global(qos: .background).async {
            self.webRTCClient.offer { [weak self] offer in
                guard
                    let `self` = self,
                    let callRoomId = self.callRoomId,
                    let calleeData = self.calleeData,
                    let callerData = self.callerData
                else { return }

                self.hasLocalSdp = true

                let roomWithOffer = [
                    "id": callRoomId,
                    "offer": [
                        "type": offer.value(forKey: "type"),
                        "sdp": offer.value(forKey: "sdp")
                    ],
                    "members": [calleeData.id, callerData.id],
                    "caller": callerData.id,
                    "callee": calleeData.id,
                    "callerData": [
                        "id": callerData.id,
                        "profilePhoto": callerData.profilePhoto,
                        "name": callerData.name
                    ],
                    "calleeData": [
                        "id": calleeData.id,
                        "profilePhoto": calleeData.profilePhoto,
                        "name": calleeData.name
                    ],
                    "status": "offer"
                ] as [String: Any]

                let roomRef = Firestore.firestore().collection("Call").document(callRoomId)
                roomRef.setData(roomWithOffer)
                //            let answerCandidates = roomRef.collection("answerCandidates")
                //            let offerCandidates = roomRef.collection("offerCandidates")
                self.roomId = roomRef.documentID
                print("Current room is \(self.roomId!) - You are the caller!")
                self.listenRoom()
                self.listenAnswerCandidates()
            }
        }
    }

    private func listenRoom() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        listener = Firestore.firestore().collection("Call").document(callRoomId).addSnapshotListener({ querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            do {
                let data = try snapshot.data(as: Call.self)
                if let dataAnswer = data.answer,
                   data.status != "close" {
                    let answer = RTCSessionDescription(type: RTCSdpType.answer, sdp: dataAnswer.sdp)
                    self.webRTCClient.set(remoteSdp: answer) { error in
                        print(error)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        })
    }

    private func listenAnswerCandidates() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        listener = Firestore.firestore()
            .collection("Call")
            .document(callRoomId)
            .collection("answerCandidates").addSnapshotListener({ [weak self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }

                snapshot.documentChanges.forEach({ documentChange in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
                            let remoteCandidate = RTCIceCandidate(
                                sdp: candidateChange.candidate,
                                sdpMLineIndex: Int32(candidateChange.sdpMLineIndex),
                                sdpMid: candidateChange.sdpMid
                            )
                            self?.webRTCClient.set(remoteCandidate: remoteCandidate) { error in
                                print(error?.localizedDescription)
                            }
                        case .modified:
                            break
                        case .removed:
                            break
                        }
                    } catch {
                        print("")
                    }
                })
            })
    }

    // MARK: - answer phone call
    private func joinARoom() {
        guard
            let callRoomId = self.callRoomId
        else { return }
        callType = .answer

        DispatchQueue.global(qos: .background).async {
            let docRef = Firestore.firestore().collection("Call").document(callRoomId)
            docRef.getDocument { document, error in
                if let document = document, document.exists {
                    let offer = try! document.data(as: Call.self).offer
                    let offerSdp = RTCSessionDescription(type: RTCSdpType.offer, sdp: offer.sdp)
                    self.webRTCClient.set(remoteSdp: offerSdp) { error in
                        print(error?.localizedDescription)
                    }

                    self.startTime = Timestamp()
                    self.webRTCClient.answer { [weak self] sdp in
                        let roomWithAnswer = [
                            "answer": [
                                "type": sdp.value(forKey: "type"),
                                "sdp": sdp.value(forKey: "sdp")
                            ],
                            "status": "answer",
                            "startTime": self?.startTime ?? Timestamp()
                        ] as [String: Any]
                        docRef.updateData(roomWithAnswer)
                        self?.listenOfferCandidates()
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
    }

    private func listenOfferCandidates() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        listener = Firestore.firestore()
            .collection("Call")
            .document(callRoomId)
            .collection("offerCandidates")
            .addSnapshotListener({ [weak self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach({ documentChange in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
//                            let data = documentChange.document.data()
                            let remoteCandidate = RTCIceCandidate(
                                sdp: candidateChange.candidate,
                                sdpMLineIndex: Int32(candidateChange.sdpMLineIndex),
                                sdpMid: candidateChange.sdpMid
                            )
                            DispatchQueue.global(qos: .background).async {
                                self?.webRTCClient.set(remoteCandidate: remoteCandidate) { error in
                                    print(error?.localizedDescription)
                                }
                            }
                        case .modified:
                            break
                        case .removed:
                            break
                        }
                    } catch {
                        print("")
                    }
                })
            })
    }
}

extension CallViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard
            let callRoomId = callRoomId,
            let sdpMid = candidate.sdpMid
        else { return }

        let docRef = Firestore.firestore().collection("Call").document(callRoomId)

        switch callType {
        case .offer:
            let offCandidate = [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": sdpMid
            ] as [String: Any]
            let offerCandidates = docRef.collection("offerCandidates")
            offerCandidates.addDocument(data: offCandidate)
        case .answer:
            let ansCandidate = [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": sdpMid
            ] as [String: Any]
            let answerCandidates = docRef.collection("answerCandidates")
            answerCandidates.addDocument(data: ansCandidate)
        }
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            print("==== .connected, .completed")

            textColor = .green
        case .disconnected:
            print("==== .disconnected")

            textColor = .orange
        case .failed, .closed:
            print("===== .failed, .closed")
            textColor = .red
        case .new, .checking, .count:

            print("==== .new, .checking, .count")
            textColor = .black
        @unknown default:
            textColor = .black
        }
    }

    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
