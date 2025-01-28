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
    
    init(callHelper: CallHelper, rtcChannel: FlutterMethodChannel?) {
        self.callHelper = callHelper
        self.rtcChannel = rtcChannel
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    static var providerConfiguration: CXProviderConfiguration {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: "splash_logo")!.pngData()
        providerConfiguration.ringtoneSound = "call.caf"
        providerConfiguration.supportedHandleTypes = Set([CXHandle.HandleType.generic])
        return providerConfiguration
    }

    // MARK: Incoming Calls

    func reportIncomingCall(uuid: UUID, hasVideo: Bool = false, payload: Extra, completion: ((NSError?) -> Void)? = nil) {
        NSLog("pushRegistry reportIncomingCall")
        if (!self.isProcessingIncomingCall) {
            NSLog("pushRegistry inside reportIncomingCall")
            self.isProcessingIncomingCall = true
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: String(payload.chat_id))
            update.localizedCallerName = payload.caller
            update.supportsHolding = false
            update.supportsGrouping = false
            update.supportsUngrouping = false
            
            NSLog("pushRegistry is calls empty \(self.callHelper.calls.isEmpty)")
            if (self.callHelper.calls.isEmpty) {
                self.configureAudioSession()
                self.rtcChannelId = payload.rtc_channel_id
                self.chatId = String(payload.chat_id)
                print("pushRegistry -> uuid = \(uuid)")
                provider.reportNewIncomingCall(with: uuid, update: update) { error in
                    guard error == nil else {
                        completion?(error as NSError?)
                        NSLog("pushRegistry reportIncomingCall fail")
                        self.isProcessingIncomingCall = false
                        return
                    }
                    let call = Call(uuid: uuid)
                    self.answerCall = call
                    self.callHelper.addCall(self.rtcChannelId ?? "Unknown", call)
                    self.timeOutTimer = Timer(
                        timeInterval: 30, repeats: false, block: { [weak self] _ in
                            self?.callTimeOut(for: call)
                        })
                    self.isVideo = payload.video_call
                    self.rtcChannel?.invokeMethod("callKitIncomingCall", arguments: [
                        "chat_id": self.chatId,
                        "rtc_channel_id": self.rtcChannelId,
                        "isVideoCall": payload.video_call
                    ])
                    NSLog("pushRegistry reportIncomingCall success")
                    self.isProcessingIncomingCall = false
                    completion?(error as NSError?)
                }
            }
        }
    }
    
    // MARK: Outgoing Calls

    func reportOutgoingCall(payload: Extra) {
        print("pushRegistry -> reportOutgoingCall")
        self.configureAudioSession()
        self.chatId = String(payload.chat_id)
        self.rtcChannelId = payload.rtc_channel_id
        let handle = CXHandle(type: .generic, value: String(payload.chat_id))
        let call = Call(uuid: UUID())
        self.callHelper.addCall(payload.rtc_channel_id ?? "Unknown", call)
        let startCallAction = CXStartCallAction(call: call.uuid, handle: handle)
        startCallAction.contactIdentifier = payload.caller
        let transaction = CXTransaction(action: startCallAction)
        callHelper.callController.request(transaction, completion: { error in
            if let error = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId,
                    "rtc_channel_id": self.rtcChannelId,
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
        print("pushRegistry -> Cancel Call Kit")
        guard let call = callHelper.getCallByKey(key: payload.rtc_channel_id) else { return };

        self.callEndFromFlutter = true
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction(action: endCallAction)
        callHelper.callController.request(transaction) {error in
            if let error = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId,
                    "rtc_channel_id": self.rtcChannelId,
                    "error": String(describing: error),
                    "isCancel": true
                ])
                NSLog("vvvv cancel error")
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
        print("pushRegistry -> accept Call Kit")
        guard let call = callHelper.getCallByKey(key: payload.rtc_channel_id) else { return };
        let handle = CXHandle(type: .generic, value: String(payload.chat_id))
        let acceptCallAction = CXAnswerCallAction(call: call.uuid)
        let transaction = CXTransaction(action: acceptCallAction)
        callHelper.callController.request(transaction, completion: { error in
            if let error = error {
                self.rtcChannel?.invokeMethod("callKitError", arguments: [
                    "chat_id": self.chatId,
                    "rtc_channel_id": self.rtcChannelId,
                    "error": String(describing: error),
                    "isCancel": false
                ])
                return
            }
            self.configureAudioSession()
            self.callTimeOut(for: call)
            self.callConnected = true
        })
    }
    
    func callTimeOut(for call: Call) {
        self.timeOutTimer?.invalidate()
        self.timeOutTimer = nil
    }
    
    func cleanUp() {
        print("pushRegistry -> cleanup progress")
        NSLog("vvv cleanup")
        self.callHelper.removeAllCalls()
        self.answerCall = nil
        self.callEndFromFlutter = false
        self.callConnected = false
        self.rtcChannelId = nil
        self.chatId = nil
        self.isVideo = 0
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
        print("pushRegistry -> Answer Call")
        guard let call = callHelper.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        self.configureAudioSession()
        self.rtcChannel?.invokeMethod("acceptCall", arguments: [
            "rtc_channel_id" : self.rtcChannelId,
            "chat_id": self.chatId,
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
        print("Provider -> Received \(#function)")
    }
    
    func configureAudioSession() {
        NSLog("configureAudioSession")
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers])
            try session.setMode(AVAudioSession.Mode.voiceChat)
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("Couldn't force audio to speaker: \(error)")
        }
    }

    func updateAudioOutputToSpeaker() {
        NSLog("updateAudioOutputToSpeaker===========> ")
//        self.setSpeaker(enabled: true)
    }
    
    func setSpeaker(enabled: Bool) {
//        do {
//            try AVAudioSession.sharedInstance().setActive(true)
//            try AVAudioSession.sharedInstance().overrideOutputAudioPort(enabled ? .speaker : .none)
//        } catch {
//            print("Failed to set speaker: \(error)")
//        }
    }
}
