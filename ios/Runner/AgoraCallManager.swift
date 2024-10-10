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
    public var remoteUserId: UInt = 0
    
    public var engine: AgoraRtcEngineKit?
    
    public var soundMgr = SoundMgr()
    
    var localVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self) // 等于flutter floatingWindow
    var fullLocalVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self)
    var remoteVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self) // 等于flutter CallView
    var fullRemoteVideo = Bundle.loadView(fromNib: "VideoViewSampleBufferDisplayView", withType: SampleBufferDisplayView.self)

    var pipController: AgoraPictureInPictureController?
    
    var floatIsLocal : Bool = true
    
    var isVoiceCall : Bool = true
    
    var isSpeaker: Bool = false
    
    var lifeState: LifeState = .didBeBackground
    
    var localFrameReady: Bool = false
    
    var localVideoMuted: Bool = false
    
    var isFrontCamera: Bool = true

    var isEnableAudio: Bool = false;
    
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

    @objc func appWillToBackgroundVersion1() {
        self.lifeState = .willBeBackground
        

        // 其他处理逻辑
        if(!userJoined || !remoteVideo.hasStream) {
            if let freezeView = self.fullRemoteVideo.freezeView {
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                
                let pixelBuffer = MediaUtils.cvPixelBufferRef(from: view.asImage() ?? UIImage()).takeRetainedValue()
                let videoFrame = AgoraOutputVideoFrame()
                videoFrame.pixelBuffer = pixelBuffer
                videoFrame.width = Int32(max(freezeView.frame.size.width, self.pipController?.displayView.frame.size.width ?? freezeView.frame.size.width))
                videoFrame.height = Int32(max(freezeView.frame.size.height, self.pipController?.displayView.frame.size.height ?? freezeView.frame.size.height))
                
                self.pipController?.displayView.reset()
                self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
            }
        }
    }
    
    @objc func appWillToBackground() {
        self.lifeState = .willBeBackground

        // 对方还没有接听的时候显示对方的头像

        if(!userJoined || !remoteVideo.hasStream){
           if let freezeView = self.fullRemoteVideo.freezeView {
               let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
               let videoFrame = AgoraOutputVideoFrame()
               videoFrame.pixelBuffer = pixelBuffer
               videoFrame.width = Int32(max(freezeView.frame.size.width, self.pipController?.displayView.frame.size.width ?? freezeView.frame.size.width))
               videoFrame.height = Int32(max(freezeView.frame.size.height, self.pipController?.displayView.frame.size.height ?? freezeView.frame.size.height))
               
               self.pipController?.displayView.reset()
               self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
           }
        }
        
        if(self.soundMgr.isRingSoundPlaying()){
            AudioUtils.shared.routeToRingBackgorundMode()
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
        
        if(self.soundMgr.isRingSoundPlaying()){
            AudioUtils.shared.routeToRingSlientMode()
        }
    }
    
    @objc func appDidToForeground() {
        //增加半秒钟的延迟，为了防止闪localVideo的frame
        self.lifeState = .didBeForeground
        self.rtcChannel?.invokeMethod("iosAppDidToForeground",arguments: nil)
    }
    
    func isAppInForeground() -> Bool{
        return self.lifeState == .didBeForeground || self.lifeState == .willBeForeground
    }
    
    func setupVideoViews(){
        self.localVideo.videoView.videoWidth = Int32(winWidth)
        self.localVideo.videoView.videoHeight = Int32(winHeight)
        self.localVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: winWidth, height: winHeight)
        self.localVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.localVideo.videoView.displayLayer.contentsGravity = .center
        self.localVideo.backgroundColor = .black
        
        self.fullLocalVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: floor(UIScreen.main.bounds.width * 5 / 3) + 48)
        self.fullLocalVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.fullLocalVideo.videoView.displayLayer.contentsGravity = .center
        self.fullLocalVideo.backgroundColor = .black
        
        self.remoteVideo.backgroundColor = .black
        self.fullRemoteVideo.backgroundColor = .black
    }
    
    func setupVideoViewsWhenIntoBackground(){
        self.localVideo.videoView.videoWidth = Int32(1)
        self.localVideo.videoView.videoHeight = Int32(1)
        self.localVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        self.localVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.localVideo.videoView.displayLayer.contentsGravity = .center
        self.localVideo.backgroundColor = .black
        
        self.fullLocalVideo.videoView.displayLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        self.fullLocalVideo.videoView.displayLayer.videoGravity = .resizeAspectFill
        self.fullLocalVideo.videoView.displayLayer.contentsGravity = .center
        self.fullLocalVideo.backgroundColor = .black
        
        self.remoteVideo.backgroundColor = .black
        self.fullRemoteVideo.backgroundColor = .black
    }
    
    
    func setPIPView(uid: UInt, avatarUrl: String, nickname: String){
        self.remoteUserId = uid
        self.avatarUrl = avatarUrl
        self.nickname = nickname
    }
    
    func initPIPController(bufferRender: AgoraSampleBufferRender?){
        if(bufferRender != nil){
            self.pipController = AgoraPictureInPictureController(displayView: bufferRender!)
        }else{
            self.pipController = AgoraPictureInPictureController(displayView: self.fullRemoteVideo.videoView)
            
            if let freezeView = self.fullRemoteVideo.freezeView {
                let pixelBuffer = MediaUtils.cvPixelBufferRef(from: self.isVoiceCall ? freezeView.asImage() ?? UIImage() : UIView(frame: CGRect(x: 0, y: 0, width: winWidth, height: winHeight)).asImage() ?? UIImage()).takeRetainedValue()
                let videoFrame = AgoraOutputVideoFrame()
                videoFrame.pixelBuffer = pixelBuffer
                videoFrame.width = Int32(freezeView.frame.size.width)
                videoFrame.height = Int32(freezeView.frame.size.height)
                
                self.pipController?.displayView.reset()
                self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
            }
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
            if(!self.localVideo.hasStream){
                if let freezeView = self.fullLocalVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.reset()
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }else{
            self.initPIPController(bufferRender: fullRemoteVideo.videoView)
            
            if(!self.remoteVideo.hasStream){
                if let freezeView = self.fullRemoteVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.reset()
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }
    }
    
    open func setupEngine(appId: String, isInviter: Bool, isVoiceCall:Bool, fps:Int, width:Int, height:Int) -> Void {
        AudioUtils.shared.setObserver()
        self.lifeState = self.isAppInForeground() ? .didBeForeground : .didBeBackground
        self.resetPipViews()
        
        self.isEnableAudio = false
        self.isInviter = isInviter
        if(isInviter && isVoiceCall){
            AudioUtils.shared.playEarpiece()
        }else{
            AudioUtils.shared.playSpeaker(isVoiceChat: self.isEnableAudio)
        }
        
        self.soundMgr.loadSounds()
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .communication
        
        self.appId = appId
        self.remoteVideo.videoView.videoWidth = Int32(width)
        self.remoteVideo.videoView.videoHeight = Int32(height)
        self.fullRemoteVideo.videoView.videoWidth = Int32(width)
        self.fullRemoteVideo.videoView.videoHeight = Int32(height)
        
        self.engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        engine?.setAINSMode(true, mode: .AINS_MODE_AGGRESSIVE)
        engine?.setAudioProfile(.speechStandard)
        engine?.enableVideo()
        engine?.disableAudio()
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
            
            if(isInviter){
                engine?.startPreview()
            }
        }
    
        setLocalFirstFrameReady()
        self.rtcChannel?.invokeMethod("callInited", arguments: [])
    }
    
    private func setupEncryption(encryptionKey: String){
        let encrtption = AgoraEncryptionConfig()
        encrtption.encryptionMode = .AES128GCM2
        encrtption.encryptionKey = encryptionKey
        
        let customByteArray: [UInt8] = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
            0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
        ]
        
        encrtption.encryptionKdfSalt = NSData(bytes: customByteArray, length: customByteArray.count) as Data
        let result = engine?.enableEncryption(true, encryptionConfig: encrtption)
    }
    
    func openSoundPermission(attempts: Int? = 0){
        self.isEnableAudio = true
        let result = engine?.enableAudio() ?? -1
        NSLog("openSoundPermission=======> \(result)")
        if(result < 0){
            if(attempts! < 1){
                self.openSoundPermission(attempts: 1)
            }else{
                self.rtcChannel?.invokeMethod("enableAudioFailed", arguments: [])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if(self.soundMgr.isBluetoothConnected() && self.soundMgr.isAudioOutputFromBluetooth() == false){
                self.soundMgr.setAudioConfig(isSpeaker: self.isVoiceCall)
            }
        }
    }
    
    func joinBroadcastStream(_ channel: String, token: String? = nil, uid: UInt = 0, isBroadcaster: Bool = true, encryptKey: String? = nil) -> Void {
        self.engine?.setVideoFrameDelegate(self)
        let opt = AgoraRtcChannelMediaOptions()
        opt.channelProfile = .communication
        opt.autoSubscribeAudio = true;
        opt.autoSubscribeVideo = true;
        opt.publishMicrophoneTrack = true;
        opt.publishCameraTrack = true;
        
        if(encryptKey != nil && !encryptKey!.isEmpty){
            self.setupEncryption(encryptionKey: encryptKey!)
        }
        
        self.engine?.joinChannel(
            byToken: token, channelId: channel,
            uid: uid, mediaOptions: opt
            
        )
        self.localUserId = uid
        if (!self.isVoiceCall) {
            toggleLocalCam(isCameraOn: true, isInit: true)
            if(!isInviter){
                engine?.startPreview()
            }
        }
        
        rtcChannel?.invokeMethod("joinChannelSuccess",arguments: nil)
    }
    
    func toggleMic(isMute:Bool){
        engine?.muteLocalAudioStream(isMute)
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
    
    //在用户没有接通电话的时候切换声道，需要修改一下agora的默认声道，不然接通后声道不生效
    func toggleSpeaker(isSpeaker:Bool){
        NSLog("toggleSpeaker===> \(isSpeaker) | \(self.isSpeaker) | \(self.userJoined)")
        if(isSpeaker != self.isSpeaker){
            self.isSpeaker = isSpeaker
        }

        if(!userJoined){
            engine?.setDefaultAudioRouteToSpeakerphone(self.isSpeaker)
        }
    }
    
    func toggleFloating(isMe: Bool){
        floatIsLocal = isMe
    }
    
    private var switchingCamera = false
    func switchCamera(){
        self.switchingCamera = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.engine?.switchCamera()
        }
        
        //防止闪
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.isFrontCamera ? 0.4 : 0.6)) { [unowned self] in
            self.switchingCamera = false
            self.isFrontCamera = !self.isFrontCamera
        }
    }
    
    func stopPiPMode(){
        if(self.pipController?.pipController.isPictureInPictureActive ?? false){
            self.pipController?.pipController.stopPictureInPicture()
        }
    }
    
    func playPickedSound(){

        // 开扬声器的时候需要delay久一些，避免声音不连续
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.isSpeaker ? 0.5 : 0.1)) { [unowned self] in
            self.soundMgr.playPickedSound(volume: 0.1) { state in
                self.soundMgr.stopPickedSound()
            }
        }
    }
    
    
    func playEndSound(){
        self.canResetSound = false
        self.soundMgr.playEndSound(volume: 1.0) { state in
            self.soundMgr.resetAllSound()
            self.canResetSound = true
        }
    }
    
    func playEnd2Sound(){
        self.canResetSound = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.soundMgr.playEnd2Sound(volume: 1.0) { state in
                self.soundMgr.resetAllSound()
                self.canResetSound = true
            }
        }
    }
    
    func playBusySound(){
        self.canResetSound = false
        self.soundMgr.playBusySound(volume: 1.0) { state in
            self.soundMgr.resetAllSound()
            self.canResetSound = true
        }
    }
    
    
    var canResetSound = true
    func releaseEngine(resetAudio: Bool) {
        self.soundMgr.stopDialingSound()
        self.soundMgr.stopPickedSound()
        
        self.localUserId = UInt(0)
        self.resetPipViews()
        
        self.pipController?.releasePIP()
        self.engine?.leaveChannel()
        
        self.allUsers.removeAll()
        self.floatIsLocal = true
        self.localFrameReady = false
        self.localVideoMuted = false
        self.isVoiceCall = true
        self.isFrontCamera = true
        self.pipController = nil
        self.isExit = false
        self.selfJoined = false
        self.userJoined = false
        self.isSpeaker = false
        self.isEnableAudio = false
        self.lifeState = self.isAppInForeground() ? .didBeForeground : .didBeBackground
        AudioUtils.shared.resetAll()
        self.destoryEngine()
    }
    
    func resetPipViews(){
        self.remoteVideo.resetToDefault()
        self.localVideo.resetToDefault()
        self.fullLocalVideo.resetToDefault()
        self.fullRemoteVideo.resetToDefault()
        
        self.fullRemoteVideo.videoView.reset()
        self.fullLocalVideo.videoView.reset()
        self.localVideo.videoView.reset()
        self.remoteVideo.videoView.reset()
    }
    
    func destoryEngine(){
        DispatchQueue.global(qos: .userInteractive).async {
            AgoraRtcEngineKit.destroy()
            self.engine = nil
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
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.selfJoined = true
        self.localUserId = uid
        self.allUsers.insert(uid)
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
        
        let data : [String: Any] = [
            "uid": String(uid),
            "cameraMuted" : muted
        ]
        
        remoteVideo.hasStream = !muted
        
        rtcChannel?.invokeMethod("onRemoteVideoStateChanged", arguments: data)
        if(muted){
            if let freezeView = self.fullRemoteVideo.freezeView {
                let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                let videoFrame = AgoraOutputVideoFrame()
                videoFrame.pixelBuffer = pixelBuffer
                videoFrame.width = Int32(freezeView.frame.size.width)
                videoFrame.height = Int32(freezeView.frame.size.height)
                
                self.pipController?.displayView.reset()
                self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
            }
        }else{
            setLocalFirstFrameReady()
            
            fullRemoteVideo.videoView.reset()
            remoteVideo.videoView.reset()
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        NSLog("didAudioMuted======> \(uid), \(muted)")
        let data : [String: Any] = [
            "uid": uid,
            "muted": muted
        ]
        
        rtcChannel?.invokeMethod("audioMuted", arguments:data)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit,
                   remoteVideoStateChangedOfUid uid: UInt,
                   state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason,
                   elapsed: Int) {
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
                if let freezeView = self.fullRemoteVideo.freezeView {
                    let pixelBuffer = MediaUtils.cvPixelBufferRef(from: freezeView.asImage() ?? UIImage()).takeRetainedValue()
                    let videoFrame = AgoraOutputVideoFrame()
                    videoFrame.pixelBuffer = pixelBuffer
                    videoFrame.width = Int32(freezeView.frame.size.width)
                    videoFrame.height = Int32(freezeView.frame.size.height)
                    
                    self.pipController?.displayView.reset()
                    self.pipController?.displayView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: true)
                }
            }
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteAudioFrameOfUid uid: UInt, elapsed: Int) {
        NSLog("firstRemoteAudioFrameOfUid====> \(uid)")
        let data : [String: Any] = [
            "uid": uid
        ]
        rtcChannel?.invokeMethod("firstRemoteAudioReceived",arguments: data)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalAudioFramePublished elapsed: Int) {
        NSLog("toggleSpeaker====> firstLocalAudioFramePublished")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        NSLog("didLeaveChannelWith=====>")
        
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
    
    private func setLocalFirstFrameReady(){
        if(!localFrameReady){
            localFrameReady = true
            rtcChannel?.invokeMethod("onFirstLocalVideoFrame",arguments: nil)
        }
    }
}

extension AgoraCallManager: AgoraVideoFrameDelegate {
    public func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        setLocalFirstFrameReady()
        
        if(lifeState != .willBeBackground && lifeState != .willBeForeground){
            if(floatIsLocal){
                if(localVideo.hasStream){
                    if(!self.isExit && !self.switchingCamera){
                        localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: self.isFrontCamera, isDefaultSize: false)
                    }
                }else{
                    remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: self.isFrontCamera, isDefaultSize:true)
                }
            }else if(self.switchingCamera == false){
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
        if(remoteVideo.hasStream){
            if(lifeState == .willBeBackground || lifeState == .didBeBackground){
                if(isExit){
                    fullLocalVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
                }else{
                    fullRemoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:true)
                }
            }else{
                if(floatIsLocal){
                    if(isExit){
                        localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:false)
                    }else{
                        remoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:true)
                        fullRemoteVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize:true)
                    }
                }else{
                    localVideo.videoView.renderVideoPixelBuffer(videoFrame, isMirror: false, isDefaultSize: false)
                }
            }
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

