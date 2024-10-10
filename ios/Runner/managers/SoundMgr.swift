//
//  SoundMgr.swift
//  Runner
//
//  Created by Venus Heng on 7/6/24.
//

import Foundation
import UIKit
import AVFoundation

public class SoundMgr: NSObject {
    private lazy var ringSoundPlayer: AVAudioPlayer? = nil
    private lazy var dialingSoundPlayer: AVAudioPlayer? = nil
    private lazy var pickedSoundPlayer: AVAudioPlayer? = nil
    private lazy var busySoundPlayer: AVAudioPlayer? = nil
    private lazy var endSoundPlayer: AVAudioPlayer? = nil
    private lazy var end2SoundPlayer: AVAudioPlayer? = nil
    
    private lazy var vibrateTimer: Timer? = nil
    
    lazy var endPlayerCallback: ((Int) -> Void)? = nil
    lazy var end2PlayerCallback: ((Int) -> Void)? = nil
    lazy var busyPlayerCallback: ((Int) -> Void)? = nil
    lazy var pickedPlayerCallback: ((Int) -> Void)? = nil
    
    public override init() {
        super.init()
    }
    
    public func loadSounds(){
        preloadRing()
        preloadDialing()
        preloadPicked()
        preloadBusy()
        preloadEnd()
        preloadEnd2()
    }
    
    public func preloadRing() {
        guard let soundFile = Bundle.main.url(forResource: "call", withExtension: "mp3") else {
            return
        }
        
        do{
            ringSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            ringSoundPlayer?.enableRate = true
            ringSoundPlayer?.numberOfLoops = 0
            ringSoundPlayer?.rate = Float(1)
            ringSoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    public func preloadDialing() {
        guard let soundFile = Bundle.main.url(forResource: "voip_ringback", withExtension: "mp3") else {
            return
        }
        
        do{
            dialingSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            dialingSoundPlayer?.enableRate = true
            dialingSoundPlayer?.numberOfLoops = 20
            dialingSoundPlayer?.rate = Float(1)
            dialingSoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    public func preloadPicked(){
        guard let soundFile = Bundle.main.url(forResource: "voip_connecting", withExtension: "mp3") else {
            return
        }
        
        do{
            pickedSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            pickedSoundPlayer?.enableRate = true
            pickedSoundPlayer?.numberOfLoops = 0
            pickedSoundPlayer?.rate = Float(1)
            pickedSoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    public func preloadBusy(){
        guard let soundFile = Bundle.main.url(forResource: "voip_busy", withExtension: "mp3") else {
            return
        }
        
        do{
            busySoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            busySoundPlayer?.enableRate = true
            busySoundPlayer?.numberOfLoops = 0
            busySoundPlayer?.rate = Float(1)
            busySoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }

    public func preloadEnd(){
        guard let soundFile = Bundle.main.url(forResource: "voip_end", withExtension: "mp3") else {
            return
        }
        
        do {
            endSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            endSoundPlayer?.enableRate = true
            endSoundPlayer?.numberOfLoops = 0
            endSoundPlayer?.rate = Float(1)
            endSoundPlayer?.prepareToPlay()
        }catch let e {
            NSLog("Error playing sound: \(e.localizedDescription)")
        }
    }
    
    public func preloadEnd2(){
        guard let soundFile = Bundle.main.url(forResource: "voip_end2", withExtension: "mp3") else {
            return
        }
        
        do {
            end2SoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            end2SoundPlayer?.enableRate = true
            end2SoundPlayer?.numberOfLoops = 0
            end2SoundPlayer?.rate = Float(1)
            end2SoundPlayer?.prepareToPlay()
        }catch let e {
            NSLog("Error playing sound: \(e.localizedDescription)")
        }
    }
    
    public func playRingSound(volume: Float){
        guard let audioPlayer = self.ringSoundPlayer else {
            return
        }
        
        AudioUtils.shared.routeToRingSlientMode()
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        
        self.startVibration(duration: 60)
        NSLog("playRingSound played")
    }
    
    public func isRingSoundPlaying() -> Bool{
        return self.ringSoundPlayer?.isPlaying ?? false
    }

    public func playDialingSound(volume: Float){
        guard let audioPlayer = self.dialingSoundPlayer else {
            return
        }
        
        if(AudioUtils.shared.hasBluetoothConnected()){
            AudioUtils.shared.playBluetooth()
        }
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        NSLog("playDialingSound played")
    }
    
    public func playPickedSound(volume: Float, callback: ((Int) -> Void)?){
        guard let audioPlayer = self.pickedSoundPlayer else {
            return
        }
        
        self.stopRingSound()
        self.stopDialingSound()
        
        if(callback != nil){
            self.pickedPlayerCallback = callback
        }
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        NSLog("playPickedSound played")
    }
    
    public func playBusySound(volume: Float, callback: ((Int) -> Void)?){
        guard let audioPlayer = self.busySoundPlayer else {
            return
        }
        
        if(callback != nil){
            self.busyPlayerCallback = callback
        }
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        NSLog("playBusySound played")
    }
    
    public func playEndSound(volume: Float, callback: ((Int) -> Void)?){
        guard let audioPlayer = self.endSoundPlayer else {
            return
        }
        
        if(callback != nil){
            self.endPlayerCallback = callback
        }
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        NSLog("playEndSound played")
    }
    
    public func playEnd2Sound(volume: Float, callback: ((Int) -> Void)?){
        guard let audioPlayer = self.end2SoundPlayer else {
            return
        }
        
        if(callback != nil){
            self.end2PlayerCallback = callback
        }
        
        audioPlayer.volume = volume
        audioPlayer.delegate = self
        audioPlayer.play()
        NSLog("playEnd2Sound played")
    }
    
    public func stopRingSound(){
        if(ringSoundPlayer?.isPlaying ?? false){
            ringSoundPlayer?.stop()
            NSLog("stopRingSound stopped")
        }
        self.stopVibration()
    }
    
    public func stopDialingSound(){
        if(dialingSoundPlayer?.isPlaying ?? false){
            dialingSoundPlayer?.stop()
            NSLog("stopDialingSound stopped")
        }
    }
    
    public func stopPickedSound(){
        if(pickedSoundPlayer?.isPlaying ?? false){
            pickedSoundPlayer?.stop()
            NSLog("stopPickedSound stopped")
        }
    }
    
    public func stopBusySound(){
        if(busySoundPlayer?.isPlaying ?? false){
            busySoundPlayer?.stop()
            NSLog("busySoundPlayer stopped")
        }
    }
    
    public func stopEndSound(){
        if(endSoundPlayer?.isPlaying ?? false){
            endSoundPlayer?.stop()
            NSLog("endSoundPlayer stopped")
        }
    }
    
    public func stopEnd2Sound(){
        if(endSoundPlayer?.isPlaying ?? false){
            endSoundPlayer?.stop()
            NSLog("end2SoundPlayer stopped")
        }
    }
    
    private func startVibration(duration: TimeInterval) {
        let startTime = Date()
        
        vibrateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            if Date().timeIntervalSince(startTime) >= duration {
                timer.invalidate()
            }
        }
    }
    
    private func stopVibration() {
        vibrateTimer?.invalidate()
    }
    
    public func resetAllSound(){
        stopRingSound()
        stopDialingSound()
        stopPickedSound()
        stopBusySound()
        stopEndSound()
        stopEnd2Sound()
        ringSoundPlayer?.currentTime = 0
        dialingSoundPlayer?.currentTime = 0
        pickedSoundPlayer?.currentTime = 0
        busySoundPlayer?.currentTime = 0
        endSoundPlayer?.currentTime = 0
        end2SoundPlayer?.currentTime = 0
        ringSoundPlayer = nil
        dialingSoundPlayer = nil
        pickedSoundPlayer = nil
        busySoundPlayer = nil
        endSoundPlayer = nil
        end2SoundPlayer = nil
    }
    
    func setAudioConfig(isSpeaker: Bool = true) {
        NSLog("setAudioConfig::\(isSpeaker)")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if(isSpeaker && !isBluetoothConnected()){
                NSLog("setAudioConfig::外放")
                try audioSession.setCategory(.playAndRecord,  options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            }else{
                NSLog("setAudioConfig::听筒")
                try audioSession.setCategory(.playAndRecord,  options: [.allowBluetooth, .allowBluetoothA2DP])
            }
            try audioSession.setActive(true)

            if let availableInputs = audioSession.availableInputs {
                for input in availableInputs {
                    if input.portType == .bluetoothA2DP || input.portType == .bluetoothLE || input.portType == .bluetoothHFP {
                        NSLog("setAudioConfig::蓝牙")
                        try audioSession.setPreferredInput(input)
                        break
                    }
                }
            }
        } catch {
            NSLog("setAudioConfig Failed to change audio session: \(error)")
        }
    }
    
    func isBluetoothConnected() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        
        if let availableInputs = audioSession.availableInputs {
            for output in availableInputs {
                if output.portType == .bluetoothA2DP || output.portType == .bluetoothLE || output.portType == .bluetoothHFP {
                    return true;
                }
            }
        }
        return false
    }

    func isAudioOutputFromBluetooth() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute

        if let output = currentRoute.outputs.first {
            if output.portType == .bluetoothA2DP || output.portType == .bluetoothLE || output.portType == .bluetoothHFP {
                return true
            }
        }
        return false
    }
    
    deinit{
        resetAllSound()
    }
}

extension SoundMgr: AVAudioPlayerDelegate{
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if(player == self.endSoundPlayer){
            self.endPlayerCallback?(2)
        } else if(player == self.busySoundPlayer){
            self.busyPlayerCallback?(2)
        } else if(player == self.pickedSoundPlayer){
            self.pickedPlayerCallback?(2)
        }else if(player == self.end2SoundPlayer){
            self.end2PlayerCallback?(2)
        }
    }
}
