//
//  ProviderDelegate.swift
//  Runner
//
//  Created by ekoo on 13/10/23.
//

import Foundation
import CallKit
import AVFoundation
import PushKit

final class ProviderDelegate: NSObject, CXProviderDelegate {

    let callHelper: CallHelper
    private let provider: CXProvider
    var answerCall: Call?
    let rtcChannel: FlutterMethodChannel?
    
    var rtcChannelId: String?
    var chatId: String?
    
    var timeOutTimer: Timer?
    var callCancelledByCaller: Bool = false
    var callEndFromFlutter: Bool = false
    var callConnected = false
    var isVideo: Int = 0
    var isProcessingIncomingCall: Bool = false
    
    lazy var callManager: AgoraCallManager? = {
        if let appDeletgate = UIApplication.shared.delegate as? AppDelegate {
            return appDeletgate.agoraCallManager
        }
        return nil
    }()
    
    init(callHelper: CallHelper, rtcChannel: FlutterMethodChannel?) {
        self.callHelper = callHelper
        self.rtcChannel = rtcChannel
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    @objc func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return
        }
        let appInFront = callManager?.isAppInForeground() ?? false
        NSLog("toggleCallkitSpeaker==> \(isOnPhoneCall()), \(appInFront)")
        if(isOnPhoneCall() && !appInFront){
            let audioSession = AVAudioSession.sharedInstance()
            for output in audioSession.currentRoute.outputs {
                if output.portType == .builtInSpeaker {
                    NSLog("toggleCallkitSpeaker==>1 Speaker: \(reasonValue), \(output.portType), \(audioSession.currentRoute.outputs)")
                    if(reasonValue == 4){
                        self.toggleCallkitSpeaker(isSpeakerEnabled: true)
                    }
                } else if output.portType == .headphones || output.portType == .bluetoothA2DP || output.portType == .bluetoothLE || output.portType == .bluetoothHFP {
                } else {
                    NSLog("toggleCallkitSpeaker==>2 Other: \(reasonValue), \(output.portType), \(audioSession.currentRoute.outputs)")
                    if(reasonValue == 3){
                        self.toggleCallkitSpeaker(isSpeakerEnabled: false)
                    }
                }
            }
        }
    }
    
    var callkitSpeakerFailedOnce = false
    func toggleCallkitSpeaker(isSpeakerEnabled: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        NSLog("toggleCallkitSpeaker==>3 \(isSpeakerEnabled), \(audioSession.category), \(audioSession.mode)")
        if(callkitSpeakerFailedOnce) { return }
        
        let options: AVAudioSession.CategoryOptions = [.duckOthers, .allowBluetooth, .allowBluetoothA2DP]
        do {
            if isSpeakerEnabled {
                try audioSession.setCategory(.playback)
            } else {
                try audioSession.setCategory(.playAndRecord, options: options)
                try audioSession.setMode(.voiceChat)
            }
            try audioSession.setActive(true)
        } catch {
            print("Failed to toggle speaker: \(error.localizedDescription)")
            NSLog("toggleCallkitSpeaker==>4 \(callkitSpeakerFailedOnce)-\(isSpeakerEnabled), category: \(audioSession.currentRoute.outputs)")
            if(!callkitSpeakerFailedOnce && isSpeakerEnabled){
                callkitSpeakerFailedOnce = true
                do {
                    NSLog("toggleCallkitSpeaker==>5 \(callkitSpeakerFailedOnce)")
                    try audioSession.setCategory(.playAndRecord, options: options)
                    try audioSession.setMode(.voiceChat)
                    try audioSession.overrideOutputAudioPort(.speaker)
                    try audioSession.setActive(true)
                } catch {
                    NSLog("Failed to toggle speaker:1 \(error.localizedDescription)")
                }
            }
        }
    }

    static var providerConfiguration: CXProviderConfiguration {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        if #available(iOS 18, *) {
            providerConfiguration.iconTemplateImageData = UIImage(named: "call_logo")?.withRenderingMode(.alwaysTemplate).pngData()
        } else {
            providerConfiguration.iconTemplateImageData = UIImage(named: "splash_logo")!.pngData()
        }
        providerConfiguration.ringtoneSound = "call.mp3"
        providerConfiguration.supportedHandleTypes = Set([CXHandle.HandleType.generic])
        return providerConfiguration
    }

    // MARK: Incoming Calls
    func reportIncomingCall(uuid: UUID, payload: Extra, completion: ((NSError?) -> Void)? = nil) {
        if (!self.isProcessingIncomingCall) {
            self.isProcessingIncomingCall = true
            self.callkitSpeakerFailedOnce = false
            
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: String(payload.chat_id))
            update.localizedCallerName = payload.caller
            update.supportsHolding = false
            update.supportsGrouping = false
            update.supportsUngrouping = false
            update.hasVideo = payload.video_call == 1
            
            if (self.callHelper.calls.isEmpty) {
                self.rtcChannelId = payload.rtc_channel_id
                self.chatId = String(payload.chat_id)
                provider.reportNewIncomingCall(with: uuid, update: update) { error in
                    guard error == nil else {
                        completion?(error as NSError?)
                        self.isProcessingIncomingCall = false
                        return
                    }
                    let call = Call(uuid: uuid)
                    self.answerCall = call
                    self.callHelper.addCall(self.rtcChannelId ?? "Unknown", call)
                    self.timeOutTimer = Timer(
                        timeInterval: 60, repeats: false, block: { [weak self] _ in
                            self?.callTimeOut(for: call)
                        })
                    self.isVideo = payload.video_call
                    NSLog("[call] callkit comming")
                    self.callManager?.isCallkit = true
                    self.rtcChannel?.invokeMethod("callKitIncomingCall", arguments: [
                        "chat_id": self.chatId ?? "",
                        "rtc_channel_id": self.rtcChannelId ?? "",
                        "isVideoCall": payload.video_call,
                        "sender_id": payload.sender_id ?? 0
                    ])
                    self.isProcessingIncomingCall = false
                    completion?(error as NSError?)
                }
            }
            
            startCheckingAudioRoute()
        }
    }
    
    var audioRouteCheckTimer: Timer?
    func startCheckingAudioRoute() {
        audioRouteCheckTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkCurrentAudioRoute), userInfo: nil, repeats: true)
    }
    
    @objc func checkCurrentAudioRoute() {
        let audioSession = AVAudioSession.sharedInstance()
        for output in audioSession.currentRoute.outputs {
//            NSLog("toggleCallkitSpeaker==> a(\(output)")
        }
    }
    
    // MARK: Outgoing Calls
    func reportOutgoingCall(payload: Extra) {
//        self.configureAudioSession()
        self.chatId = String(payload.chat_id)
        self.rtcChannelId = payload.rtc_channel_id
        let handle = CXHandle(type: .generic, value: String(payload.chat_id))
        let call = Call(uuid: UUID())
        self.callHelper.addCall(payload.rtc_channel_id , call)
        let startCallAction = CXStartCallAction(call: call.uuid, handle: handle)
        startCallAction.contactIdentifier = payload.caller
        startCallAction.isVideo = payload.video_call == 1
        let transaction = CXTransaction(action: startCallAction)
        callHelper.callController.request(transaction, completion: { error in
            if let error = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId ?? "",
                    "rtc_channel_id": self.rtcChannelId ?? "",
                    "error": String(describing: error),
                    "isCancel": false
                ])
                return
            }
            self.answerCall = call
        })
    }
    
    func outgoingCallConnected(payload: Extra) {
        print("pushRegistry -> outgoingCallConnected")
        
        if self.callConnected == false {
            guard let call = callHelper.getCallByKey(key: payload.rtc_channel_id) else { return };
            self.callConnected = true
            provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
        }
    }
    
    func cancelCallKit(payload: Extra) {
        guard let call = callHelper.getCallByKey(key: payload.rtc_channel_id) else { return };
        self.callEndFromFlutter = true
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction(action: endCallAction)
        callHelper.callController.request(transaction) {error in
            if let err = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId ?? "",
                    "rtc_channel_id": self.rtcChannelId ?? "",
                    "error": String(describing: err),
                    "isCancel": true
                ])
                NSLog("vvvv cancel error \(err)")
                self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: .remoteEnded)
                call.endCall()
                self.cleanUp()
                self.callTimeOut(for: call)
                return
            }
        }
        provider.reportCall(with: call.uuid, endedAt: Date(), reason: .remoteEnded)
        self.cleanUp()
        self.callTimeOut(for: call)
    }

    func acceptCallKit(payload: Extra) {
        guard let call = callHelper.getCallByKey(key: payload.rtc_channel_id) else { return };
        let acceptCallAction = CXAnswerCallAction(call: call.uuid)
        let transaction = CXTransaction(action: acceptCallAction)
        callHelper.callController.request(transaction, completion: { error in
            if let error = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId ?? "",
                    "rtc_channel_id": self.rtcChannelId ?? "",
                    "error": String(describing: error),
                    "isCancel": false
                ])
                return
            }
//            self.configureAudioSession()
            self.callTimeOut(for: call)
            self.callConnected = true
        })
    }
    
    func callTimeOut(for call: Call) {
        self.timeOutTimer?.invalidate()
        self.timeOutTimer = nil
    }
    
    func cleanUp() {
        self.callkitSpeakerFailedOnce = false
        self.callHelper.removeAllCalls()
        self.answerCall = nil
        self.callEndFromFlutter = false
        self.callConnected = false
        self.rtcChannelId = nil
        self.chatId = nil
        self.isVideo = 0
        self.audioRouteCheckTimer?.invalidate()
        self.audioRouteCheckTimer = nil
    }

    // MARK: CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("pushRegistry -> Start Call")
        let update = CXCallUpdate()
        update.remoteHandle = action.handle
        update.localizedCallerName = action.contactIdentifier
        self.provider.reportCall(with: action.callUUID, updated: update)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = callHelper.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        self.configureAudioSession()
        self.rtcChannel?.invokeMethod("acceptCall", arguments: [
            "rtc_channel_id" : self.rtcChannelId ?? "",
            "chat_id": self.chatId ?? "",
            "isVideo": self.isVideo,
        ])
        self.callTimeOut(for: call)
        self.callConnected = true
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("pushRegistry -> End Call")
        guard let call = callHelper.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        if !self.callEndFromFlutter {
            print("pushRegistry -> call cancel from call kit")
            // need to invoke method
            if (self.callConnected) {
                self.rtcChannel?.invokeMethod("hangupCall", arguments: [
                    "chat_id": self.chatId,
                    "rtc_channel_id": self.rtcChannelId,
                ])
            } else {
                self.rtcChannel?.invokeMethod("rejectCall", arguments: [
                    "chat_id": self.chatId,
                    "rtc_channel_id": self.rtcChannelId,
                ])
            }
        }
        
        // Report the call as ended
        provider.reportCall(with: action.uuid, endedAt: Date(), reason: self.callConnected ? .remoteEnded :.unanswered)
        
        action.fulfill()

        call.endCall()
        self.callTimeOut(for: call)
        self.cleanUp()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("CXSetMutedCallAction=========> \(action.isMuted)")
        guard let call = callHelper.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        call.isMuted = action.isMuted

        self.rtcChannel?.invokeMethod("muteCall", arguments: [
            "is_muted": action.isMuted,
        ])

        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Provider -> didActivate \(audioSession.currentRoute)")
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Provider -> Received")
    }
    
    func configureAudioSession() {
        NSLog("configureAudioSession")
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            try session.setMode(.voiceChat)
            try session.overrideOutputAudioPort(.none)
        } catch {
            print("Failed to change audio session(Callkit): \(error)")
        }
    }
    
    func isOnPhoneCall() -> Bool {
        for call in CXCallObserver().calls {
            if call.hasEnded == false {
                return true
            }
        }
        return false
    }
    
    deinit {
        self.cleanUp()
        NotificationCenter.default.removeObserver(AVAudioSession.routeChangeNotification)
    }
}
