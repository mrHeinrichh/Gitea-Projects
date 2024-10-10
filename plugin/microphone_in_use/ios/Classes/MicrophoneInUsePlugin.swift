import Flutter
import UIKit
import AVFoundation

public class MicrophoneInUsePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "microphone_in_use", binaryMessenger: registrar.messenger())
    let instance = MicrophoneInUsePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "isMicrophoneInUse":
      result(self.isMicrophoneInUse())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    private func isMicrophoneInUse() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let mode = audioSession.mode
        if  //mode == AVAudioSession.Mode.voiceChat ||
            mode == AVAudioSession.Mode.videoRecording ||
            mode == AVAudioSession.Mode.videoChat ||
            mode == AVAudioSession.Mode.gameChat {
            return true
        } else {
            do {
                try audioSession.setCategory(.playAndRecord)
                try audioSession.setActive(true)
            } catch {
                return true
            }
            return false
        }
    }
}
