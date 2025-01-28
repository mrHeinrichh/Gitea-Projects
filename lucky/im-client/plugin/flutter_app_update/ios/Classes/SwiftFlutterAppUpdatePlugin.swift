import Flutter
import UIKit

public class SwiftFlutterAppUpdatePlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_app_update", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterAppUpdatePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var arguments: [String: AnyObject]
        if(call.arguments != nil){
            arguments = call.arguments as! [String: AnyObject]
        }else{
            arguments = [String: AnyObject]()
        }
        switch call.method{
        case "checkAppVersion":
            let useSystemUI: Bool = arguments["useSystemUI"] as! Bool
            let appid: String = arguments["appid"] as! String
            checkAppUpdate(appid: appid, useSystemUI: useSystemUI, result: result)
        case "checkLowMinVersion":
            let minVersion: String = arguments["minVersion"] as! String
            checkLowMinVersion(minVersion:minVersion, result: result)
        case "openURL":
            let url: String = arguments["url"] as! String
            openURL(url: URL(string: url)!)
            result(nil)
        default:
            result(FlutterError(code: "404", message: "No such method", details: nil))
        }
    }
    
    //版本号比较
    private func compareVersion(str1: String, str2: String) -> Bool {
        let compareResult = str1.compare(str2, options: .numeric, range: nil, locale: nil)
        return (compareResult == .orderedAscending)
    }
    
    private func checkLowMinVersion(minVersion:String, result: @escaping FlutterResult){
        let infoDict:Dictionary = Bundle.main.infoDictionary!
        var app_Version:String = infoDict["CFBundleShortVersionString"] as! String
        let bundleVersion = infoDict["CFBundleVersion"] as! String
        if(!bundleVersion.isEmpty){
            app_Version.append("+"+bundleVersion)
        }
        let isOlder = app_Version.isOlder(than: minVersion)
        result(isOlder)
    }
    
    private func checkAppUpdate(appid:String, useSystemUI:Bool, result: @escaping FlutterResult){
        //本地版本信息
        let infoDict:Dictionary = Bundle.main.infoDictionary!
        var app_Version:String = infoDict["CFBundleShortVersionString"] as! String
        let bundleVersion = infoDict["CFBundleVersion"] as! String
        if(!bundleVersion.isEmpty){
            app_Version.append("+"+bundleVersion)
        }
        let now = NSDate()
        let timeInterval = now.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        let url = "http://itunes.apple.com/cn/lookup?id=" + appid + "&t=" + String(timeStamp)
        Http.request(method: .GET, url: url, complete: {r in
            let jsonData:Data = r.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])
            let resultDict = json as? [String: Any]
            let tempArr = resultDict?["results"] as? [[String: Any]]
            if let resultsArr = tempArr {
                if resultsArr.count < 1 {
                    print("此APPID为未上架的APP或者查询不到")
                    result(nil)
                    return
                }
                let itunesVersion = resultsArr.first!["version"] as! String
                //trackViewUrl 为更新地址
                let trackViewUrl = resultsArr.first!["trackViewUrl"] as! String
                let releaseNotes = resultsArr.first!["releaseNotes"] as! String
                let isOlder = app_Version.isOlder(than: itunesVersion)
                var arguments: [String: AnyObject] = [String: AnyObject]()
                arguments["isOlder"] = isOlder as AnyObject
                arguments["releaseNotes"] = releaseNotes as AnyObject
                
                if(useSystemUI){
                    if isOlder {
                        
                        var alertController = UIAlertController()
                        alertController = UIAlertController(title: "版本更新", message: "有新的可用版本，是否前往更新。", preferredStyle: .alert)
                        let certainAction = UIAlertAction(title: "确定", style: .default) { (action) in
                            arguments["action"] = 1 as AnyObject
                            result(arguments)
                            let url = URL(string: trackViewUrl)
                            self.openURL(url:url!)
                        }
                        let cancelAction = UIAlertAction(title: "取消", style: .default) { (action) in
                            arguments["action"] = 0 as AnyObject
                            result(arguments)
                        }
                        alertController.addAction(cancelAction)
                        alertController.addAction(certainAction)
                        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                    }
                    else{
                        var alertController = UIAlertController()
                        alertController = UIAlertController(title: "版本更新", message: "您的版本已是最新，无需更新。", preferredStyle: .alert)
                        let certainAction = UIAlertAction(title: "确定", style: .default) { (action) in
                            arguments["action"] = 1 as AnyObject
                            result(arguments)
                        }
                        alertController.addAction(certainAction)
                        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                    }
                }
                else{
                    arguments["url"] = trackViewUrl as AnyObject
                    result(arguments)
                }
            }
        }, error:{error in
            print("请求出错了:",error.debugDescription)
            result(nil)
        })
    }
    
    private func openURL(url: URL){
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension String
{
    func ck_compare(with version: String) -> ComparisonResult {
        return compare(version, options: .numeric, range: nil, locale: nil)
    }
    
    func isNewer(than aVersionString: String) -> Bool {
        return ck_compare(with: aVersionString) == .orderedDescending
    }
    
    func isOlder(than aVersionString: String) -> Bool {
        return ck_compare(with: aVersionString) == .orderedAscending
    }
    
    func isSame(to aVersionString: String) -> Bool {
        return ck_compare(with: aVersionString) == .orderedSame
    }
}

//定义请求类型
enum HttpMethod {
    case GET,
         POST
}

//在http中定义类方法来做请求，方便使用
class Http {
    class func request(method:HttpMethod, url:String,params:[String:Any]=[:],complete: @escaping(_ _result:String)->Void,error:@escaping(_ _error:Error?)->Void){
        var url = url
        //处理参数为了方便这里抽取里一个方法来处理参数
        let param = self.parserParams(params: params)
        //设置get请求参数
        if method == .GET && param != "" {
            if url.contains("?"){
                url.append("&\(param)")
            }else{
                url.append("?\(param)")
            }
        }
        // 注意这里需要将含有中文的参数进行编码处理，否则创建URL 对象就会返回nil。
        url = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let _url = URL(string: url)!
        let request = NSMutableURLRequest(url: _url)
        //设置超时时间
        request.timeoutInterval=50
        //设置请求方式
        request.httpMethod = method == .GET ? "GET" : "POST"
        //设置post请求参数
        if method == .POST && param != ""{
            request.httpBody=param.data(using: .utf8)
        }
        let session = URLSession.shared
        let httpTask = session.dataTask(with: request as URLRequest) { (data,response ,err ) in
            //在主线程中回调方便在界面处理数据逻辑
            OperationQueue.main.addOperation {
                if err != nil{
                    //错误回调
                    error(err)
                    return
                }
                //请求成功将结果返回
                complete(String(data: data!, encoding:String.Encoding.utf8)!)
            }
        }
        //启动任务
        httpTask.resume()
    }
    
    //将字典转换成网络请求的参数字符串
    private class func parserParams(params:[String:Any])->String{
        var newStr=""
        for param in params{
            newStr.append("\(param.key)=\(param.value)&")
        }
        return newStr
    }
}
