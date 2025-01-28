//
//  AgoraCallManager.swift
//  Runner
//
//  Created by Virginia Loke Sin Yee on 27/2/24.
//
import AgoraRtcKit
import SwiftUI
import Foundation
import AVFoundation
import SDWebImage

open class AgoraCallManager: NSObject, ObservableObject {
    
    let rtcChannel: FlutterMethodChannel?
    
    let winWidth = 120.0
    let winHeight = 200.0
    let avatarSize = 80.0
    
    public var appId: String = ""
    public var isInviter: Bool = false
    
    /// The set of all users in the channel.
    public var allUsers: Set<UInt> = []
    
    /// Integer ID of the local user.
    public var localUserId: UInt = 0
    public var avatarUrl: String = ""
    public var nickname: String = ""
    
    public var engine: AgoraRtcEngineKit?
    
    private var soundMgr = SoundMgr()
    
    var localVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self) // 等于flutter floatingWindow
    var fullLocalVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self)
    var remoteVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self) // 等于flutter CallView

    var pipController: AgoraPictureInPictureController?
    
    var floatIsLocal : Bool = true
    
    var isVoiceCall : Bool = true
    
    var enableSpeaker: Bool = true
    
    var lifeState: LifeState = .didBeForeground
    
    var localFrameReady: Bool = false
    
    var localVideoMuted: Bool = false
    
    var isFrontCamera: Bool = true
    
    var isExit: Bool = false
    
    var selfJoined: Bool = false
    var userJoined: Bool = false

    init(rtcChannel: FlutterMethodChannel?) {
        self.rtcChannel = rtcChannel
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.setupVideoViews()
    }

    @objc func appWillToBackground() {
        self.lifeState = .willBeBackground
        if(!remoteVideo.hasStream){
            remoteVideo.videoView.reset()
        }
        
        // 对方还没有接听的时候显示对方的头像
        if(!userJoined || !remoteVideo.hasStream){
            if let freezeView = self.remoteVideo.freezeView {
                let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                let videoFrame = AgoraOutputVideoFrame()
                videoFrame.pixelBuffer = pixelBuffer
                videoFrame.width = Int32(max(freezeView.frame.size.width, self.pipController?.displayView.frame.size.width ?? freezeView.frame.size.width))
                videoFrame.height = Int32(max(freezeView.frame.size.height, self.pipController?.displayView.frame.size.height ?? freezeView.frame.size.height))
                
                
                NSLog("buildAvatar===========> \(self.pipController?.displayView), \(self.remoteVideo.videoView), \(videoFrame.width), \(videoFrame.height), \(freezeView.frame.size.width), \(freezeView.frame.size.height)")
                
                self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
            }
        }
    }
    
    @objc func appDidToBackground() {
        //增加半秒钟的延迟，为了防止闪localVideo的frame
        self.lifeState = .didBeBackground
        self.rtcChannel?.invokeMethod("iosAppDidToBackground",arguments: nil)
    }
    
    @objc func appWillToForeground() {
        self.lifeState = .willBeForeground
        
        let isOneStreamBigBlank = (localVideo.hasStream && !remoteVideo.hasStream && !self.floatIsLocal) || (!localVideo.hasStream && remoteVideo.hasStream && !self.floatIsLocal)
        if(self.pipController?.pipController.isPictureInPictureActive ?? false && isOneStreamBigBlank){
            self.pipController?.isStopping = true
        }

        if(localVideo.hasStream){
            if(floatIsLocal){
                localVideo.videoView.reset()
            }else{
                remoteVideo.videoView.reset()
            }
        }
    }
    
    @objc func appDidToForeground() {
        //增加半秒钟的延迟，为了防止闪localVideo的frame
        self.lifeState = .didBeForeground
        self.rtcChannel?.invokeMethod("iosAppDidToForeground",arguments: nil)
    }
    
    func setupVideoViews(){
        self.localVideo.videoView.videoWidth = Int32(winWidth)
        self.localVideo.videoView.videoHeight = Int32(winHeight)
        self.localVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: winWidth, height: winHeight)
        self.localVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.localVideo.videoView.displayLayer.contentsGravity = .center
        self.localVideo.backgroundColor = .black
        
        self.remoteVideo.backgroundColor = .black
        
        self.fullLocalVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: floor(UIScreen.main.bounds.width * 5 / 3) + 48)
        self.fullLocalVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.fullLocalVideo.videoView.displayLayer.contentsGravity = .center
        self.fullLocalVideo.backgroundColor = .black
    }
    
    func setPIPView(uid: UInt, avatarUrl: String, nickname: String){
        self.avatarUrl = avatarUrl
        self.nickname = nickname
    }
    
    func initPIPController(bufferRender: AgoraSampleBufferRender?){
        if(bufferRender != nil){
            self.pipController = AgoraPictureInPictureController(displayView: bufferRender!)
        }else{
            self.pipController = AgoraPictureInPictureController(displayView: self.remoteVideo.videoView)
        }
        self.pipController?.pipController.setValue(1, forKey: "controlsStyle")
        self.pipController?.pipController.setValue(2, forKey: "controlsStyle")
    }
    
    func onExitCallView(isExit: Bool){
        self.isExit = isExit
        self.pipController?.releasePIP()
        self.pipController = nil
        
        if(isExit){
            self.initPIPController(bufferRender: fullLocalVideo.videoView)
            NSLog("onExitCallView=========> \(self.pipController?.displayView), \(self.fullLocalVideo.videoView)")
            if(!self.fullLocalVideo.hasStream){
                if let freezeView = self.fullLocalVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }else{
            self.initPIPController(bufferRender: remoteVideo.videoView)
            
            if(!self.remoteVideo.hasStream){
                if let freezeView = self.remoteVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }
    }
    
    open func setupEngine(appId: String, isInviter: Bool, isVoiceCall:Bool, fps:Int, width:Int, height:Int) -> Void {
        self.isInviter = isInviter
        self.enableSpeaker = !isVoiceCall
        
        if(self.enableSpeaker){
            self.soundMgr.setAudioToSpeaker()
        }
        self.soundMgr.loadSounds()
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .communication
        
        self.appId = appId
        self.remoteVideo.videoView.videoWidth = Int32(width)
        self.remoteVideo.videoView.videoHeight = Int32(height)
        
        self.engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        engine?.setAINSMode(true, mode: .AINS_MODE_AGGRESSIVE)
        engine?.setAudioProfile(.speechStandard)
        engine?.enableVideo()
        engine?.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(width: width, height: height, frameRate: AgoraVideoFrameRate(rawValue: fps)!, bitrate: 0, orientationMode: AgoraVideoOutputOrientationMode.fixedPortrait, mirrorMode: AgoraVideoMirrorMode.auto))
        
        if(isVoiceCall){
            self.localVideoMuted = true
            engine?.enableLocalVideo(false)
            engine?.setDefaultAudioRouteToSpeakerphone(false)
            engine?.setEnableSpeakerphone(false)
            engine?.muteLocalVideoStream(true)
        } else {
            self.isVoiceCall = false
            self.floatIsLocal = false
            self.localVideoMuted = false
            engine?.enableLocalVideo(true)
            engine?.setDefaultAudioRouteToSpeakerphone(true)
            engine?.setEnableSpeakerphone(true)
            engine?.muteLocalVideoStream(false)
            engine?.setLocalRenderMode(.hidden, mirror: .disabled)
            engine?.startPreview()
        }
    
        self.rtcChannel?.invokeMethod("callInited",arguments: [])
    }
    
    func joinBroadcastStream(
        _ channel: String, token: String? = nil,
        uid: UInt = 0, isBroadcaster: Bool = true
    ) -> Void {
        self.engine?.setVideoFrameDelegate(self)
        let opt = AgoraRtcChannelMediaOptions()
        opt.channelProfile = .communication
        opt.clientRoleType = .broadcaster
        opt.autoSubscribeAudio = true;
        opt.autoSubscribeVideo = true;
        opt.publishMicrophoneTrack = true;
        opt.publishCameraTrack = true;
        self.engine?.joinChannel(
            byToken: token, channelId: channel,
            uid: uid, mediaOptions: opt
        )
        self.localUserId = uid
        if (!self.isVoiceCall) {
            toggleLocalCam(isCameraOn: true, isInit: true)
        }
        rtcChannel?.invokeMethod("joinChannelSuccess",arguments: nil)
    }

    func releaseEngine() {
        self.soundMgr.stopDialingSound()
        
        if(self.userJoined){
            if(!self.isVoiceCall){
                self.soundMgr.setAudioToSpeaker()
            }
            self.soundMgr.playEndSound { state in
                NSLog("PlatEndSoundDone=======>")
                self.soundMgr.resetAllSound()
            }
        }
        
        self.pipController?.releasePIP()
        self.engine?.leaveChannel()
        self.localUserId = UInt(0)
        self.remoteVideo.resetToDefault()
        self.localVideo.resetToDefault()
        self.fullLocalVideo.resetToDefault()
        self.remoteVideo.videoView.reset()
        self.fullLocalVideo.videoView.reset()
        self.localVideo.videoView.reset()
        self.allUsers.removeAll()
        self.floatIsLocal = true
        self.localFrameReady = false
        self.localVideoMuted = false
        self.isVoiceCall = true
        self.isFrontCamera = true
        self.pipController = nil
        self.isExit = false
        self.enableSpeaker = true
        self.selfJoined = false
        self.userJoined = false
    }
    
    func destoryEngine(){
        AgoraRtcEngineKit.destroy()
        self.engine = nil
    }
    
    func toggleMic(isMute:Bool){
        engine?.muteLocalAudioStream(isMute)
    }
    
    func toggleSpeaker(isSpeaker:Bool){
        self.enableSpeaker = isSpeaker
        if(!self.selfJoined){
            engine?.setDefaultAudioRouteToSpeakerphone(isSpeaker)
        }else{
            engine?.setEnableSpeakerphone(isSpeaker)
        }
    }
    
    func toggleLocalCam(isCameraOn:Bool, isInit: Bool = false){
        engine?.muteLocalVideoStream(!isCameraOn)
        engine?.enableLocalVideo(isCameraOn)
        if(isCameraOn){
            self.localVideoMuted = false
            toggleSpeaker(isSpeaker: true)
            if (isInit){
                self.rtcChannel?.invokeMethod("cameraIsInit",arguments: [])
            }
        }else{
            self.localVideoMuted = true
        }
    }
    
    func toggleFloating(isMe: Bool){
        floatIsLocal = isMe
    }
    
    func switchCamera(){
        engine?.switchCamera()
        self.isFrontCamera = !self.isFrontCamera
    }
    
    func stopPiPMode(){
        if(self.pipController?.pipController.isPictureInPictureActive ?? false){
            self.pipController?.pipController.stopPictureInPicture()
        }
    }
    
    deinit{
        NotificationCenter.default.removeObserver(#selector(appWillToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(appDidToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(appWillToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(appDidToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
    
// MARK: - Delegate Methods

extension AgoraCallManager: AgoraRtcEngineDelegate {
    /// The delegate is telling us that the local user has successfully joined the channel.
    /// - Parameters:
    ///    - engine: The Agora RTC engine kit object.
    ///    - channel: The channel name.
    ///    - uid: The ID of the user joining the channel.
    ///    - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.
    ///
    /// If the client's role is `.broadcaster`, this method also adds the broadcaster's
    /// userId (``localUserId``) to the ``allUsers`` set.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.selfJoined = true
        self.localUserId = uid
        self.allUsers.insert(uid)
        
        if(isInviter){
            self.soundMgr.playDialingSound()
        }
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        self.allUsers.insert(uid)
        self.userJoined = true
        
        let data : [String: Any] = [
            "uid": String(uid)
        ]
        soundMgr.stopDialingSound()
        rtcChannel?.invokeMethod("onUserJoined",arguments: data)
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        self.allUsers.remove(uid)
        
        if (uid == self.localUserId) {
            rtcChannel?.invokeMethod("CallEnd", arguments:nil)
          } else {
            rtcChannel?.invokeMethod("CallOptEnd", arguments:nil)
          }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        let data : [String: Any] = [
            "uid": uid,
            "txQuality": txQuality.rawValue,
            "rxQuality": rxQuality.rawValue
        ]
        rtcChannel?.invokeMethod("onNetworkQuality",arguments:data)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        NSLog("Agora Call Manager ::\(errorCode)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        NSLog("didVideoMuted muted::\(muted), \(uid), \(self.localVideoMuted)")
        
        //暂时在对方开视频的时候就开启本地视频流，防止自己开视频的时候对方关掉后自己的视频流停止的问题
        if(!muted){
            self.engine?.enableLocalVideo(true)
        }
        
        let data : [String: Any] = [
            "uid": String(uid),
            "cameraMuted" : muted
        ]
        rtcChannel?.invokeMethod("onRemoteVideoStateChanged", arguments: data)
        if(muted){
            if let freezeView = self.remoteVideo.freezeView {
                let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                let videoFrame = AgoraOutputVideoFrame()
                videoFrame.pixelBuffer = pixelBuffer
                videoFrame.width = Int32(freezeView.frame.size.width)
                videoFrame.height = Int32(freezeView.frame.size.height)
                
                self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
            }
        }else{
            remoteVideo.videoView.reset()
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit,
                   remoteVideoStateChangedOfUid uid: UInt,
                   state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason,
                   elapsed: Int) {
        NSLog("remoteVideoStateChangedOfUid=====> \(state), \(reason), \(floatIsLocal)")
        if(state == AgoraVideoRemoteState.starting || state == AgoraVideoRemoteState.decoding){
            remoteVideo.hasStream = true
        }else{
            remoteVideo.hasStream = false
        }
        
        let data : [String: Any] = [
            "uid": String(uid),
            "cameraMuted" : !remoteVideo.hasStream
        ]
        rtcChannel?.invokeMethod("onRemoteVideoStateChanged", arguments: data)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStateChangedOf state: AgoraVideoLocalState, reason: AgoraLocalVideoStreamReason, sourceType: AgoraVideoSourceType) {
        if(state == AgoraVideoLocalState.capturing || state == AgoraVideoLocalState.encoding){
            localVideo.hasStream = true
        }else if(state == AgoraVideoLocalState.stopped || state == AgoraVideoLocalState.failed){
            localVideo.hasStream = false
        }
        
        NSLog("localVideoStateChangedOfUid=====> \(state), \(reason), \(localVideo.hasStream), \(isVoiceCall), \(floatIsLocal), \(lifeState), \(pipController?.isStopping)")
        
        if(reason.rawValue == 7){
            if(!remoteVideo.hasStream){
                if let freezeView = self.remoteVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int, sourceType: AgoraVideoSourceType) {
        NSLog("firstLocalVideoFrameWith=====> \(size.width), \(size.height)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        NSLog("didLeaveChannelWith=====> 1 \(self.userJoined)")
        self.destoryEngine()
    }
    
    func getShortName() -> String{
        var name = "-"
        if(!self.remoteVideo.nickname.isEmpty){
            let nickname = self.remoteVideo.nickname
            
            if(nickname.firstCharacterIsEmoji){
                name = String(nickname.first!)
            }else{
                let parts = nickname.split(separator: " ")
                if(parts.count > 1){
                    name = "\(String(parts[0].first!))\(String(parts[1].first!))".uppercased()
                }else{
                    name = String(nickname.first!).uppercased()
                }
            }
        }
        
        return name
    }
}

extension AgoraCallManager: AgoraVideoFrameDelegate {
    public func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        if(!localFrameReady){
            localFrameReady = true
            rtcChannel?.invokeMethod("onFirstLocalVideoFrame",arguments: nil)
        }
        
        if(lifeState != .willBeBackground && lifeState != .willBeForeground){
            if(floatIsLocal){
                if(localVideo.hasStream){
                    if(!self.isExit){
                        localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: self.isFrontCamera, isDefaultSize: false)
                    }
                }else{
                    remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: self.isFrontCamera, isDefaultSize:true)
                }
            }else{
                let stopping = self.pipController?.isStopping ?? false
                if(!stopping && lifeState == .didBeForeground){
                    remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: self.isFrontCamera, isDefaultSize:true)
                }
            }
        }
        
        return true
    }
    
    // 先把pipcontroller 的 display换成floating 的view，因为local的View关掉了
    public func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        if(lifeState != .willBeBackground){
            if(floatIsLocal){
                if(isExit){
                    fullLocalVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
                    localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:false)
                }else{
                    remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:true)
                }
            }else{
                fullLocalVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
                localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
            }
        }else{
            remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:true)
        }
        
        return true
    }
    
    public func getVideoFormatPreference() -> AgoraVideoFormat {
        .cvPixelBGRA
    }
    
    public func getRotationApplied() -> Bool {
        true
    }
    
    public func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        return .readWrite
    }
}

enum LifeState {
    case willBeBackground
    case didBeBackground
    case willBeForeground
    case didBeForeground
}

