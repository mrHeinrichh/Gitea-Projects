//
//  AudioUtils.swift
//  Runner
//
//  Created by Venus Heng on 29/8/24.
//

import Foundation
import CallKit

class AudioUtils: NSObject {
    static let shared = AudioUtils()
    var audioOutputs: [AVAudioSessionPortDescription] = []
    lazy var routeCallback: ((String, Bool, String) -> Void)? = nil
    
    lazy var callManager: AgoraCallManager? = {
        if let appDeletgate = UIApplication.shared.delegate as? AppDelegate {
            return appDeletgate.agoraCallManager
        }
        return nil
    }()
    
    private override init() {
        super.init()
        audioOutputs = AVAudioSession.sharedInstance().currentRoute.outputs
    }
    
    func setObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    func playBluetooth(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.none)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func playSpeakerForVoice(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func playSpeaker(isVoiceChat: Bool){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if(isVoiceChat){
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            }else{
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            }
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func playEarpiece(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.none)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func routeToDialing(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func routeToRingBackgorundMode(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    func routeToRingSlientMode(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.soloAmbient)
            try audioSession.setActive(true)
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        NSLog("handleRouteChange=====> \(reason)")
        switch reason {
        case .newDeviceAvailable:
            self.handleConnect()
            break
        case .oldDeviceUnavailable:
            self.handleDisconnect()
            break
        case .categoryChange:
            handleCallkitRoute(isSpeaker: false)
            break
        case .override:
            handleCallkitRoute(isSpeaker: true)
            updateCurrentCallkitOutputs(reason: AVAudioSession.RouteChangeReason.override)
            break
        default:
            break
        }
    }
    
    func handleCallkitRoute(isSpeaker: Bool){
        let appInFront = callManager?.isAppInForeground() ?? false
        let isCallkitFront: Bool = isOnPhoneCall() && !appInFront
        if(isCallkitFront){
            for output in AVAudioSession.sharedInstance().currentRoute.outputs {
                if output.portType == .builtInSpeaker {
                    if isSpeaker {
                        self.toggleCallkitSpeaker(isSpeakerEnabled: true)
                    }
                } else if output.portType == .builtInReceiver {
                    if !isSpeaker {
                        self.toggleCallkitSpeaker(isSpeakerEnabled: false)
                    }
                }
            }
        }
    }
    
    var callkitSpeakerFailedOnce = false
    func toggleCallkitSpeaker(isSpeakerEnabled: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        
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
            if(!callkitSpeakerFailedOnce && isSpeakerEnabled){
                callkitSpeakerFailedOnce = true
                do {
                    try audioSession.setCategory(.playAndRecord, options: options)
                    try audioSession.setMode(.voiceChat)
                    try audioSession.overrideOutputAudioPort(.speaker)
                    try audioSession.setActive(true)
                } catch {
                    NSLog("Failed to toggle speaker again: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 蓝牙已连接
    internal func handleConnect() {
        updateCurrentCallkitOutputs(reason: AVAudioSession.RouteChangeReason.newDeviceAvailable)
    }
    
    // 蓝牙已断开
    internal func handleDisconnect() {
        // Get the current route outputs
//        let currentOutputs = AVAudioSession.sharedInstance().currentRoute.outputs
        
        
        // Find the device that was removed
//        let removedOutputs = audioOutputs.filter { oldOutput in
//            !currentOutputs.contains { $0.uid == oldOutput.uid }
//        }
        
//        audioOutputs.removeAll { oldOutput in
//            !currentOutputs.contains { $0.uid == oldOutput.uid }
//        }
//        
//        NSLog("getCurrentOutputs======> handleDisconnect: \(audioOutputs)")
//        if let cb = self.routeCallback{
//            cb(audioOutputs.first?.portName ?? "", audioOutputs.first == nil ? false : isBluetooth(output: audioOutputs.first!), audioOutputs.first?.portType.rawValue ?? "")
//        }
        updateCurrentCallkitOutputs(reason: AVAudioSession.RouteChangeReason.oldDeviceUnavailable)
    }
    
    func setRouteChangeCallback(callback: @escaping ((String, Bool, String) -> Void)){
        self.routeCallback = callback
    }

    func hasBluetoothConnected() -> Bool{
        return self.getAvailableBluetooths().isEmpty == false
    }
    
    func getAvailableBluetooths() -> [String]{
        NSLog("getCurrentOutputs======> get: \(audioOutputs)")
        var list: [String] = []
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        for output in audioOutputs {
            if output.portType == .bluetoothA2DP || output.portType == .bluetoothLE || output.portType == .bluetoothHFP {
                list.append(output.portName)
            }
        }
        return list
    }
    
    func getCurrentOutput() -> String{
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        if currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            return "speaker"
        } else if currentRoute.outputs.contains(where: { $0.portType == .builtInReceiver }) {
            return "earpiece"
        } else{
            if(currentRoute.outputs.first != nil){
                return currentRoute.outputs.first?.portName ?? "unknown"
            }
        }
        
        return "unknown"
    }
    
    func updateCurrentCallkitOutputs(reason: AVAudioSession.RouteChangeReason){
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        
        let output1 = audioOutputs.sorted(by: { output1, output2 in
            output1.portName < output2.portName
        }).first
        
        let output2 = outputs.sorted(by: { output1, output2 in
            output1.portName < output2.portName
        }).first
        
        let isSame = output1?.uid == output2?.uid && output1?.portType == output2?.portType
        NSLog("updateCurrentCallkitOutputs===> \(isSame), \(reason)")
        if(!isSame){
            if(reason == AVAudioSession.RouteChangeReason.newDeviceAvailable || reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable){
                audioOutputs = outputs
            }
            
            if let cb = self.routeCallback, let device = audioOutputs.first {
                cb(device.portName, self.isBluetooth(output: device), device.portType.rawValue)
            }
        }
    }
    
    func isBluetooth(output: AVAudioSessionPortDescription) -> Bool {
        return output.portType == AVAudioSession.Port.bluetoothA2DP ||
            output.portType == AVAudioSession.Port.bluetoothLE ||
            output.portType == AVAudioSession.Port.bluetoothHFP
    }
    
    func isOnPhoneCall() -> Bool {
        for call in CXCallObserver().calls {
            if call.hasEnded == false {
                return true
            }
        }
        return false
    }
    
    func resetAll(){
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    deinit {
        NSLog("getCurrentOutputs======> deinit")
        resetAll()
    }
}
