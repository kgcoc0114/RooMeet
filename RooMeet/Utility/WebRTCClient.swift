//
//  WebRTCClient.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/7.
//

import Foundation
import WebRTC
import FirebaseFirestore

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
}

final class WebRTCClient: NSObject {

    private let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let mediaConstrains = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
    ]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    private var cameraDevicePosition: AVCaptureDevice.Position = .front

    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }

    required init(iceServers: [String]) {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]

        config.sdpSemantics = .unifiedPlan

        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )

        let peerConnection = self.factory.peerConnection(with: config, constraints: constraints, delegate: nil)

        self.peerConnection = peerConnection

        super.init()

        self.createMediaSenders()
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }

    // MARK: - Signaling
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(
            mandatoryConstraints: self.mediaConstrains,
            optionalConstraints: nil
        )

        self.peerConnection.offer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp) { _ in
                completion(sdp)
            }
        }
    }

    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(
            mandatoryConstraints: self.mediaConstrains,
            optionalConstraints: nil
        )

        self.peerConnection.answer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp) { _ in
                completion(sdp)
            }
        }
    }

    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }

    func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> Void) {
        self.peerConnection.add(remoteCandidate)
    }

    // MARK: - Media
    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
                .sorted { f1Camera, f2Camera -> Bool in
                    let width1 = CMVideoFormatDescriptionGetDimensions(f1Camera.formatDescription).width
                    let width2 = CMVideoFormatDescriptionGetDimensions(f2Camera.formatDescription).width
                    return width1 < width2
                }).last,
            let fps = (format.videoSupportedFrameRateRanges
                .sorted {
                    return $0.maxFrameRate < $1.maxFrameRate
                }.last) else { return }

        capturer.startCapture(
            with: frontCamera,
            format: format,
            fps: Int(fps.maxFrameRate)
        )

        self.localVideoTrack?.add(renderer)
    }

    func swapToBackCamera() {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        capturer.stopCapture {
            let position = self.cameraDevicePosition == .front ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
            self.cameraDevicePosition = position
            guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
                return
            }

            guard
                let camera = RTCCameraVideoCapturer.captureDevices().first { $0.position == self.cameraDevicePosition },
                let format = (RTCCameraVideoCapturer.supportedFormats(for: camera)
                    .sorted { f1Camera, f2Camera -> Bool in
                        let width1 = CMVideoFormatDescriptionGetDimensions(f1Camera.formatDescription).width
                        let width2 = CMVideoFormatDescriptionGetDimensions(f2Camera.formatDescription).width
                        return width1 < width2
                    }).last,
                let fps = (format.videoSupportedFrameRateRanges
                    .sorted {
                        return $0.maxFrameRate < $1.maxFrameRate
                    }.last) else { return }

            capturer.startCapture(
                with: camera,
                format: format,
                fps: Int(fps.maxFrameRate)
            )
        }
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }

    private func configureAudioSession() {
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }

    private func createMediaSenders() {
        let streamId = "stream"

        let audioTrack = self.createAudioTrack()
        self.localAudioTrack = audioTrack
        self.peerConnection.add(audioTrack, streamIds: [streamId])

        let videoTrack = self.createVideoTrack()
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: [streamId])
        self.remoteVideoTrack = self.peerConnection.transceivers.first {
            $0.mediaType == .video
        }?.receiver.track as? RTCVideoTrack

        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }

    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.factory.audioSource(with: audioConstrains)
        let audioTrack = self.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }

    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = self.factory.videoSource()
        videoSource.adaptOutputFormat(toWidth: 1280, height: 720, fps: 30)
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let videoTrack = self.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }

    // MARK: - Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }

    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
    }

    func closeConnection() {
        if localVideoTrack != nil {
            localVideoTrack = nil
        }

        if remoteVideoTrack != nil {
            remoteVideoTrack = nil
        }

        if localAudioTrack != nil {
            localAudioTrack = nil
        }


        if videoCapturer != nil {
            videoCapturer = nil
        }

        self.localDataChannel?.close()
        self.remoteDataChannel?.close()

        remoteDataChannel = nil
        localDataChannel = nil

        self.peerConnection.close()
        self.delegate = nil
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if candidate.sdpMid != nil {
            self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
        } else {
            print("empty ice event")
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        switch newState {
        case .new:
            print("peerConnection newState new")
        case .connecting:
            print("peerConnection newState connecting")
        case .connected:
            print("peerConnection newState connected")
        case .disconnected:
            print("peerConnection newState disconnected")
        case .failed:
            print("peerConnection newState failed")
        case .closed:
            print("peerConnection newState closed")
        @unknown default:
            break
        }
    }
}

extension WebRTCClient {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
}

// MARK: - Video control
extension WebRTCClient {
    func hideVideo() {
        self.setVideoEnabled(false)
    }
    func showVideo() {
        self.setVideoEnabled(true)
    }
    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
}

// MARK: - Audio control
extension WebRTCClient {
    func muteAudio() {
        self.setAudioEnabled(false)
    }

    func unmuteAudio() {
        self.setAudioEnabled(true)
    }

    func speakerOff() {
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try rtcAudioSession.overrideOutputAudioPort(.none)
        } catch let error {
            debugPrint("Error setting AVAudioSession category: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }

    func speakerOn() {
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try rtcAudioSession.overrideOutputAudioPort(.speaker)
            try rtcAudioSession.setActive(true)
        } catch let error {
            debugPrint("Couldn't force audio to speaker: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }

    private func setAudioEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        debugPrint("didReceiveMessageWith")
    }
}
