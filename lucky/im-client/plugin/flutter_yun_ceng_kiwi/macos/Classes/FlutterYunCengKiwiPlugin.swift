import Cocoa
import FlutterMacOS

let kiwi_init_default : Int32 = 999;
var kiwi_init_value : Int32 = kiwi_init_default;

typealias SwiftInitCallback = @convention(c) (Int32) -> Void

func initCallback(result: Int32) {
    print("Kiwi init with value: \(result)")
    kiwi_init_value = result;
}

public class FlutterYunCengKiwiPlugin: NSObject, FlutterPlugin {
    private var _token: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_yun_ceng_kiwi", binaryMessenger: registrar.messenger)
        let instance = FlutterYunCengKiwiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "initEx":
            self.initExWith(methodCall: call, result: result)
        case "initAsync":
            self.initAsync(methodCall: call, result: result)
        case "isInitDone":
            self.isInitDone(methodCall: call, result: result)
        case "getProxyTcpByDomain":
            self.getProxyTcpByDomain(methodCall: call, result: result)
        case "onNetworkOn":
            self.onNetworkOn(methodCall: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func initExWith(methodCall: FlutterMethodCall, result: FlutterResult){
        guard let arg = methodCall.arguments as? Dictionary<String, Any> else {
            result(FlutterError.init(code: "-5", message: "bad args", details: nil))
            return;
        }

        if let appKey = arg["appKey"] as? String,
        let token = arg["token"] {
            _token = token as? String
            let res = KiwiInit(appKey.UTF8CString);
            kiwi_init_value = res;
            result(res)
            return;
        }
        
        result(FlutterError.init(code: "-2", message: "app key is nul", details: nil))
        return;
    }

    public func initAsync(methodCall: FlutterMethodCall, result: FlutterResult){
        guard let arg = methodCall.arguments as? Dictionary<String, Any> else {
            result(FlutterError.init(code: "-5", message: "bad args", details: nil))
            return;
        }

        kiwi_init_value = kiwi_init_default;
        if let appKey = arg["appKey"] as? String,
        let token = arg["token"] {
            _token = token as? String
            let callback: SwiftInitCallback = initCallback
            let res = KiwiInitWithListner(appKey.UTF8CString, callback);
            kiwi_init_value = res;
            result(0)
            return;
        }
        
        result(FlutterError.init(code: "-2", message: "app key is nul", details: nil))
        return;
    }

    public func isInitDone(methodCall: FlutterMethodCall, result: FlutterResult){
        if (kiwi_init_value != kiwi_init_default) {
            result(0);
        } else {
            result(1);
        }
    }
    
    public func getProxyTcpByDomain(methodCall: FlutterMethodCall, result: FlutterResult) {
        if _token == nil {
            result(FlutterError.init(code: "-1", message: "游戏盾未初始化!", details: nil))
        }
        
        guard let arg = methodCall.arguments as? Dictionary<String, Any> else {
            result(FlutterError.init(code: "-5", message: "bad args", details: nil))
            return;
        }

        if let domain = arg["group_name"] as? String {
            
            let ip: [UInt8] = Array(repeating: 0, count: 128);
            let port: [UInt8] = Array(repeating: 0, count: 40);
            
            
            let ipString = String(decoding: ip, as: UTF8.self)
            let portString =  String(decoding: port, as: UTF8.self)
            
            let ret = KiwiServerToLocal(domain.UTF8CString, ipString.UTF8CString, Int32(ip.count), portString.UTF8CString, Int32(port.count))
            
            var dict: Dictionary = Dictionary<String, Any>()
            if(String(cString: portString.toCString()).isEmpty == false){
                dict["target_port"] = String(cString: portString.toCString())
            }
            
            if(String(cString: ipString.toCString()).isEmpty == false){
                dict["target_ip"] = String(cString: ipString.toCString())
            }
            
            dict["code"] = ret
            result(dict)
            return;
        }
        
        result(FlutterError.init(code: "-1", message: "arg is nil", details: nil))
        return;
    }

    public func onNetworkOn(methodCall: FlutterMethodCall, result: FlutterResult){
        KiwiOnNetworkOn();
        result(0);
    }
}

extension String{
    
    // String 转化为  char *
    func toCString(usig encoding: String.Encoding = .utf8)->UnsafePointer<CChar>{
        let data = self.data(using: encoding)!
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: bytes, count: data.count)
        return UnsafeRawPointer(bytes).assumingMemoryBound(to: CChar.self)
    }
    
    var UTF8CString: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer<Int8>(mutating: (self as NSString).utf8String!)
    }
    
}
