import Flutter
import UIKit

public class SwiftFlutterCaptchaPlugin: NSObject, FlutterPlugin {
    
    public static var channel : FlutterMethodChannel?
    let captchaManager = CaptchaManager()

  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "flutter_captcha", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCaptchaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if(call.method == "getPlatformVersion"){
          result("iOS " + UIDevice.current.systemVersion)
      } else if(call.method == "verify"){
          captchaManager.startVerify()
      }
  }
}
