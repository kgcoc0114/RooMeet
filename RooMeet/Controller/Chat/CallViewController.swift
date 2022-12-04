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
    private var webRTCClient: WebRTCClient! = WebRTCClient(iceServers: Config.default.webRTCIceServers)

    private var hasLocalSdp = false
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

    @IBOutlet weak var swapCameraButton: UIButton! {
        didSet {
            swapCameraButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var saveImageButton: UIButton! {
        didSet {
            saveImageButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var startVideoButton: UIButton! {
        didSet {
            startVideoButton.setTitle("", for: .normal)
            startVideoButton.tintColor = .mainLightColor
            startVideoButton.isHidden = true
        }
    }

    @IBOutlet weak var hangUpButtonView: UIImageView! {
        didSet {
            let hangUpTapGR = UITapGestureRecognizer(target: self, action: #selector(hangUpTapped))

            hangUpButtonView.isUserInteractionEnabled = true
            hangUpButtonView.addGestureRecognizer(hangUpTapGR)
        }
    }

    @IBOutlet weak var answerButtonView: UIImageView! {
        didSet {
            let answerTapGR = UITapGestureRecognizer(target: self, action: #selector(answerTapped))

            answerButtonView.isUserInteractionEnabled = true
            answerButtonView.animationDuration = 10
            answerButtonView.addGestureRecognizer(answerTapGR)
        }
    }

    @IBOutlet weak var callerImageView: UIImageView! {
        didSet {
            callerImageView.contentMode = .scaleAspectFill
        }
    }

    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.textColor = .white
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @IBOutlet weak var localVideoView: UIView! {
        didSet {
            localVideoView.isHidden = true
            localVideoView.backgroundColor = .darkGray.withAlphaComponent(0.4)
            localVideoView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
            localVideoView.clipsToBounds = true
        }
    }

    @IBOutlet weak var remoteVideoView: UIView! {
        didSet {
            remoteVideoView.isHidden = true
            remoteVideoView.backgroundColor = .darkGray.withAlphaComponent(0.4)
        }
    }

    @IBOutlet weak var hintLabel: UILabel! {
        didSet {
            hintLabel.text = "等候中..."
            hintLabel.font = UIFont.regularSubTitle()
            hintLabel.textColor = .mainLightColor
        }
    }

    @IBOutlet weak var callTimeLabel: UILabel! {
        didSet {
            callTimeLabel.text = ""
            callTimeLabel.isHidden = true
            callTimeLabel.textColor = .white
            callTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private var callRoomListener: ListenerRegistration?
    private var answerCandidatesListener: ListenerRegistration?
    private var offerCandidatesListener: ListenerRegistration?

    lazy var animationView = RMLottie.shared.callAnimationView

    init(callRoomId: String, callType: CallType, callerData: ChatMember, calleeData: ChatMember) {
        super.init(nibName: "CallViewController", bundle: nil)

        self.callRoomId = callRoomId
        self.callType = callType
        self.callerData = callerData
        self.calleeData = calleeData

        if callerData.id != UserDefaults.id {
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

        view.addSubview(animationView)

        animationView.isHidden = false

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            animationView.heightAnchor.constraint(equalToConstant: 70),
            animationView.topAnchor.constraint(equalTo: callerNameLabel.topAnchor, constant: 30)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUp()
        listenCall()

        guard let otherUserData = otherUserData else {
            return
        }

        if let profilePhoto = otherUserData.profilePhoto {
            callerImageView.loadImage(profilePhoto, placeHolder: UIImage.asset(.roomeet))
        } else {
            callerImageView.image = UIImage.asset(.roomeet)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        callRoomListener?.remove()
        answerCandidatesListener?.remove()
        offerCandidatesListener?.remove()
    }

    override func viewDidLayoutSubviews() {
        callerImageView.layer.cornerRadius = callerImageView.bounds.width / 2
        hangUpButtonView.layer.cornerRadius = hangUpButtonView.bounds.width / 2
        answerButtonView.layer.cornerRadius = answerButtonView.bounds.width / 2
    }

    deinit {
        webRTCClient = nil
    }

    func setUp() {
        if callType == .offer {
            offerDidTap()
        }
    }

    func listenCall() {
        guard let callRoomId = callRoomId else { return }
        FirestoreEndpoint.call.colRef.document(callRoomId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                guard
                    let document = documentSnapshot,
                    document.data() != nil else {
                    print("Document data was empty.")
                    return
                }

                do {
                    let call = try document.data(as: Call.self)
                    var status: String = ""
                    self.callStatus = call.status

                    switch call.status {
                    case "startVideo":
                        self.startVideo()
                        self.updateComponentStatus(answer: true, status: true, startVideo: true)
                    case "close":
                        status = "結束通話"
                        self.updateComponentStatus(answer: true)
                        DispatchQueue.global(qos: .background).async {
                            self.webRTCClient.closeConnection()
                        }
                        self.dismiss(animated: true)
                    case "answer":
                        self.startTime = call.startTime
                        self.updateComponentStatus(answer: true)
                        status = "開始通話中"
                        self.animationView.isHidden = true
                        RMLottie.shared.endCallAnimate(animationView: self.animationView)
                    case "offer":
                        self.startTime = call.startTime
                        if call.caller == UserDefaults.id {
                            self.updateComponentStatus(answer: true, status: true, startVideo: true)
                        } else {
                            self.updateComponentStatus(status: true, startVideo: true)
                        }
                        RMLottie.shared.startCallAnimate(animationView: self.animationView)
                    case "cancel":
                        status = ""
                        self.dismiss(animated: true)
                    default:
                        status = ""
                    }

                    DispatchQueue.main.async {
                        self.statusLabel.text = status
                        if let otherUserData = self.otherUserData {
                            self.callerNameLabel.text = otherUserData.name
                        } else {
                            self.callerNameLabel.text = "有人打電話來了"
                        }

                        guard let callTime = call.callTime else {
                            self.callTimeLabel.isHidden = true
                            return
                        }
                        self.callTimeLabel.text = "通話時間: \(callTime)"
                    }
                    print(call.status)
                } catch {
                    print("error: ", error)
                }
            }
    }

    func updateComponentStatus(
        hangUp: Bool = false,
        answer: Bool = false,
        status: Bool = false,
        callTime: Bool = false,
        startVideo: Bool = false
    ) {
        startVideoButton.isHidden = startVideo
        hangUpButtonView.isHidden = hangUp
        answerButtonView.isHidden = answer
        statusLabel.isHidden = status
        callTimeLabel.isHidden = callTime
    }

    @objc private func hangUpTapped() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.webRTCClient.closeConnection()
        }

        // 自播自己取消
        if callStatus == "offer" && callType == .offer {
            updateCallData(status: "cancel", content: "通話已取消")
            // 掛對方來電
        } else if callStatus == "offer" && callType == .answer {
            updateCallData(status: "cancel", content: "通話已取消")
        } else {
            // 正常通話結束
            if callStatus != "close" {
                dealWithHangUp()
            }
        }

        dismiss(animated: true)
    }

    @objc private func answerTapped() {
        joinARoom()
    }

    @IBAction private func videoDidTap(_ sender: UIButton) {
        updateVideoCallData(status: "startVideo")
        startVideo()
    }

    @IBAction func swapCamera(_ sender: Any) {
        webRTCClient.swapToBackCamera()
    }

    private func startVideo() {
        let localRenderer = RTCMTLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCMTLVideoView(frame: remoteVideoView.frame)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill

        webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        webRTCClient.renderRemoteVideo(to: remoteRenderer)

        if let localVideoView = localVideoView {
            self.embedView(localRenderer, into: localVideoView)
        }

        embedView(remoteRenderer, into: remoteVideoView)
        remoteVideoView.sendSubviewToBack(remoteRenderer)

        hintLabel.isHidden = true
        remoteVideoView.isHidden = false
        localVideoView.isHidden = false
        self.webRTCClient.speakerOn()
    }

    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            view.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        containerView.layoutIfNeeded()
    }

    private func dealWithHangUp() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.webRTCClient.closeConnection()
        }

        endTime = Timestamp()
        guard
            let sTime = startTime,
            let eTime = endTime else {
            return
        }
        callTime = RMDateFormatter.shared.getTimeIntervalString(startTimestamp: sTime, endTimestamp: eTime)
        updateCallData(status: "close", content: callTime ?? "")
    }


    func updateVideoCallData(status: String) {
        guard
            let callRoomId = self.callRoomId
        else { return }

        let docRef = FirestoreEndpoint.call.colRef.document(callRoomId)
        let updateData = [
            "status": status
        ]
        docRef.updateData(updateData)
    }

    func updateCallData(status: String, content: String) {
        guard
            let callRoomId = self.callRoomId,
            let callerData = self.callerData
        else { return }

        let docRef = FirestoreEndpoint.call.colRef.document(callRoomId)
        var updateData: [AnyHashable: Any]
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
}

// MARK: - webRTC
extension CallViewController {
    // MARK: - create phone call
    private func offerDidTap() {
        DispatchQueue.global(qos: .background).async {
            self.webRTCClient.offer { [weak self] offer in
                guard
                    let self = self,
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

                let roomRef = FirestoreEndpoint.call.colRef.document(callRoomId)
                roomRef.setData(roomWithOffer)
                self.roomId = roomRef.documentID

                self.listenRoom()
                self.listenAnswerCandidates()
            }
        }
    }

    private func listenRoom() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        callRoomListener = FirestoreEndpoint.call.colRef
            .document(callRoomId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error as Any)")
                    return
                }
                do {
                    let data = try snapshot.data(as: Call.self)
                    if let dataAnswer = data.answer, data.status != "close" {
                        let answer = RTCSessionDescription(type: RTCSdpType.answer, sdp: dataAnswer.sdp)
                        self.webRTCClient.set(remoteSdp: answer) { error in
                            print(error as Any)
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
    }

    private func listenAnswerCandidates() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        answerCandidatesListener = FirestoreEndpoint.call.colRef
            .document(callRoomId)
            .collection("answerCandidates")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(String(describing: error))")
                    return
                }

                snapshot.documentChanges.forEach { documentChange in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
                            let remoteCandidate = RTCIceCandidate(
                                sdp: candidateChange.candidate,
                                sdpMLineIndex: Int32(candidateChange.sdpMLineIndex),
                                sdpMid: candidateChange.sdpMid
                            )
                            self.webRTCClient.set(remoteCandidate: remoteCandidate) { error in
                                guard let error = error else { return }
                                print(error.localizedDescription)
                            }
                        case .modified:
                            break
                        case .removed:
                            break
                        }
                    } catch {
                        print("")
                    }
                }
            }
    }

    // MARK: - answer phone call
    private func joinARoom() {
        guard
            let callRoomId = self.callRoomId
        else { return }

        callType = .answer

        DispatchQueue.global(qos: .background).async {
            let docRef = FirestoreEndpoint.call.colRef.document(callRoomId)
            docRef.getDocument { document, error in
                if let document = document, document.exists {
                    guard let offer = try? document.data(as: Call.self).offer else { return }
                    let offerSdp = RTCSessionDescription(type: RTCSdpType.offer, sdp: offer.sdp)
                    self.webRTCClient.set(remoteSdp: offerSdp) { error in
                        guard let error = error else { return }
                        print(error.localizedDescription)
                    }

                    self.startTime = Timestamp()
                    self.webRTCClient.answer { [weak self] sdp in
                        guard let `self` = self else { return }

                        let roomWithAnswer = [
                            "answer": [
                                "type": sdp.value(forKey: "type"),
                                "sdp": sdp.value(forKey: "sdp")
                            ],
                            "status": "answer",
                            "startTime": self.startTime ?? Timestamp()
                        ] as [String: Any]
                        docRef.updateData(roomWithAnswer)
                        self.listenOfferCandidates()
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

        offerCandidatesListener = FirestoreEndpoint.call.colRef
            .document(callRoomId)
            .collection("offerCandidates")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(String(describing: error))")
                    return
                }
                snapshot.documentChanges.forEach { documentChange in
                    do {
                        let candidateChange = try documentChange.document.data(as: Candidate.self)
                        switch documentChange.type {
                        case .added:
                            let remoteCandidate = RTCIceCandidate(
                                sdp: candidateChange.candidate,
                                sdpMLineIndex: Int32(candidateChange.sdpMLineIndex),
                                sdpMid: candidateChange.sdpMid
                            )

                            DispatchQueue.global(qos: .background).async {
                                self?.webRTCClient.set(remoteCandidate: remoteCandidate) { error in
                                    print(error?.localizedDescription as Any)
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
                }
            }
    }
}

extension CallViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard
            let callRoomId = callRoomId,
            let sdpMid = candidate.sdpMid
        else { return }

        let docRef = FirestoreEndpoint.call.colRef.document(callRoomId)

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
        self.state = state
    }
}
