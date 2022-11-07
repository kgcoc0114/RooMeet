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
    var chatRoom: ChatRoom?
    var callType: CallType = .offer
    var roomId: String?

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var answerButton: UIButton!
    @IBOutlet weak var hangUpButton: UIButton!

    private var listener: ListenerRegistration?

    init(chatRoom: ChatRoom, callType: CallType) {
        super.init(nibName: "CallViewController", bundle: nil)
        self.chatRoom = chatRoom
        self.callType = callType
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
            statusLabel.text = "開始講話"
            joinARoom()

        }
    }
    func listenCall() {
        Firestore.firestore().collection("Call").document(chatRoom!.id)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                do {
                    let call = try document.data(as: Call.self)
                    print("====", call.status)
                    var status: String
                    switch call.status {
                    case "close":
                        status = "結束通話"
                        // TODO: callKit
                        // delete call 資料
                        // 算時間
                        // 回寫到 messge 的 cell 裏面
                    case "answer":
                        status = "開始通話中"
                    default:
                        status = "等待對方回覆中"
                    }
                    DispatchQueue.main.async {
                        self?.statusLabel.text = status
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

    @IBAction func hangUp(_ sender: Any) {
        webRTCClient.closeConnection()
        let docRef = Firestore.firestore().collection("Call").document(chatRoom!.id)

        docRef.updateData([
            "status": "close",
            "endTime": Timestamp()
        ])
    }

    func delete() {
        Firestore.firestore().collection("Call").document(chatRoom!.id).delete() { err in
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
        self.webRTCClient.offer { [weak self] (offer) in
            guard let `self` = self else { return }
            self.hasLocalSdp = true
            let roomWithOffer = [
                "offer": [
                    "type": offer.value(forKey: "type"),
                    "sdp": offer.value(forKey: "sdp")
                ],
                "members": self.chatRoom?.members as Any,
                "caller": gCurrentUser.id,
                "status": "offer",
                "startTime": Timestamp()
            ] as [String : Any]

            let roomRef = Firestore.firestore().collection("Call").document(self.chatRoom!.id)
            roomRef.setData(roomWithOffer)
            let answerCandidates = roomRef.collection("answerCandidates")
            let offerCandidates = roomRef.collection("offerCandidates")
            self.roomId = roomRef.documentID
            print("Current room is \(self.roomId!) - You are the caller!")
            self.listenRoom()
            self.listenAnswerCandidates()
        }
    }

    private func listenRoom() {
        listener = Firestore.firestore().collection("Call").document(chatRoom!.id).addSnapshotListener({ querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshot results: \(error!)")
                return
            }
            do {
                let data = try snapshot.data(as: Call.self)
                print(data)
                if ((data.answer) != nil) {
                    let answer = RTCSessionDescription(type: RTCSdpType.answer, sdp: data.answer!.sdp)
                    self.webRTCClient.set(remoteSdp: answer) { error in
                        print(error)
                    }
                }
            } catch  {
                print("")
            }
        })
    }

    private func listenAnswerCandidates() {
        listener = Firestore.firestore()
            .collection("Call").document(chatRoom!.id)
            .collection("answerCandidates").addSnapshotListener({ [weak self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }

                snapshot.documentChanges.forEach({ (documentChange) in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
                            let data = documentChange.document.data()
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
        callType = .answer
        let docRef = Firestore.firestore().collection("Call").document(chatRoom!.id)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let offer = try! document.data(as: Call.self).offer
                let offerSdp = RTCSessionDescription(type: RTCSdpType.offer, sdp: offer.sdp)
                self.webRTCClient.set(remoteSdp: offerSdp) { error in
                    print(error?.localizedDescription)
                }
                self.webRTCClient.answer { sdp in
                    let roomWithAnswer = [
                        "answer": [
                            "type": sdp.value(forKey: "type"),
                            "sdp": sdp.value(forKey: "sdp")
                        ],
                        "status": "answer"
                    ] as [String : Any]
                    docRef.updateData(roomWithAnswer)
                    self.listenOfferCandidates()
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    private func listenOfferCandidates() {
        listener = Firestore.firestore()
            .collection("Call").document(chatRoom!.id)
            .collection("offerCandidates").addSnapshotListener({ [weak self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach({ (documentChange) in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
                            let data = documentChange.document.data()
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
}

extension CallViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        let docRef = Firestore.firestore().collection("Call").document(chatRoom!.id)

        switch callType {
        case .offer:
            print("offerofferofferofferoffer offCandidate")
            let offCandidate = [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid!
            ] as [String : Any]

            let offerCandidates = docRef.collection("offerCandidates")
            offerCandidates.addDocument(data: offCandidate)
        case .answer:
            let ansCandidate = [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid!
            ] as [String : Any]

            let answerCandidates = docRef.collection("answerCandidates")
            answerCandidates.addDocument(data: ansCandidate)
        }
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        print("====", state)
        switch state {
        case .connected, .completed:
            textColor = .green
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
//        print("state.description.capitalized ", RTCIceConnectionState(rawValue: state.rawValue))
//        print("textColor ", textColor)
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
