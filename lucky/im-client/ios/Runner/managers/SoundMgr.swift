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
    private lazy var dialingSoundPlayer: AVAudioPlayer? = nil
    private lazy var endSoundPlayer: AVAudioPlayer? = nil
    
    lazy var endPlayerCallback: ((Int) -> Void)? = nil
    
    public override init() {
        super.init()
    }
    
    public func loadSounds(){
        preloadDialing()
        preloadEnd()
    }
    
    public func preloadDialing() {
        guard let soundFile = Bundle.main.url(forResource: "dialing_sound", withExtension: "mp3") else {
            return
        }
        
        do{
            dialingSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            dialingSoundPlayer?.enableRate = true
            dialingSoundPlayer?.numberOfLoops = 10
            dialingSoundPlayer?.rate = Float(1)
            dialingSoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    public func preloadEnd(){
        guard let soundFile = Bundle.main.url(forResource: "call_end_sound", withExtension: "mp3") else {
            return
        }
        
        do {
            endSoundPlayer = try AVAudioPlayer(contentsOf: soundFile)
            endSoundPlayer?.enableRate = true
            endSoundPlayer?.numberOfLoops = 0
            endSoundPlayer?.rate = Float(1)
            endSoundPlayer?.prepareToPlay()
        }catch{
            NSLog("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    public func playDialingSound(){
        guard var audioPlayer = self.dialingSoundPlayer else {
            return
        }
        do{
            audioPlayer.volume = 1.0
            audioPlayer.delegate = self
            audioPlayer.play()
            NSLog("playDialingSound played")
        } catch let e {
            NSLog("playDialingSound Error: \(e)")
        }
    }
    
    public func playEndSound(callback: ((Int) -> Void)?){
        guard var audioPlayer = self.endSoundPlayer else {
            return
        }
        
        if(callback != nil){
            self.endPlayerCallback = callback
        }
        
        do{
            audioPlayer.volume = 1.0
            audioPlayer.delegate = self
            audioPlayer.play()
            NSLog("playEndSound played")
        } catch let e {
            NSLog("playEndSound Error: \(e)")
        }
    }
    
    public func stopDialingSound(){
        if(dialingSoundPlayer?.isPlaying ?? false){
            dialingSoundPlayer?.stop()
            NSLog("stopDialingSound stopped")
        }
    }
    
    public func stopEndSound(){
        if(endSoundPlayer?.isPlaying ?? false){
            endSoundPlayer?.stop()
            NSLog("endSoundPlayer stopped")
        }
    }
    
    public func resetAllSound(){
        stopDialingSound()
        stopEndSound()
        dialingSoundPlayer?.currentTime = 0
        endSoundPlayer?.currentTime = 0
        dialingSoundPlayer = nil
        endSoundPlayer = nil
    }
    
    func setAudioToSpeaker(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            NSLog("resetAudioSetting======> 1 \(audioSession.category)")
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            NSLog("resetAudioSetting======> 2 \(audioSession.category)")
        } catch {
            print("Failed to check background audio: \(error)")
        }
    }
    
    deinit{
        resetAllSound()
        stopDialingSound()
        stopEndSound()
    }
}

extension SoundMgr: AVAudioPlayerDelegate{
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NSLog("audioPlayerDidFinishPlaying=====> \(player == self.dialingSoundPlayer), \(player == self.endSoundPlayer)")
        if(player == self.endSoundPlayer){
            self.endPlayerCallback?(2)
        }
    }
}
