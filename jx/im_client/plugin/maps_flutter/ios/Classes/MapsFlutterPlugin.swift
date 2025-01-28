import Flutter
import UIKit

public class MapsFlutterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
      let factory = AppleMapViewFactory(withRegistrar: registrar)
      registrar.register(factory, withId: "appleNativeMapView")      
      let factory2 = AppleMapPreviewFactory(withRegistrar: registrar)
      registrar.register(factory2, withId: "appleNativePreviewMapView")
//     let channel = FlutterMethodChannel(name: "maps_flutter", binaryMessenger: registrar.messenger())
    let instance = MapsFlutterPlugin()
//     registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
