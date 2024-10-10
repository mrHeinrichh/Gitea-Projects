//
//  KiwiManager.swift
//  ImagePublish
//
//  Created by Venus Heng on 16/1/24.
//

import Foundation

let appHost = "kiwi_api"
let ver = 21040101
let token = "token"
let key = "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"

class KiwiManager: NSObject {
    static let shared = KiwiManager();
    
    var apiUrl: String = ""
    var port: Int = 0
    
    override init() {
        super.init()
    }
    
    func initKiwi(ipReady: ((_ ip: String, _ port: Int) -> Void)?){
        Kiwi.`init`(withListener: (key as NSString).utf8String) { code in
            NSLog("jxim======> initKiwi \(code)")
            if code == 0{
                if let ipInfo: IpInfo = self.getProxyTcpByDomain() {
                    ipReady?(ipInfo.ip, ipInfo.port)
                }
            }
        }
    }
    
    func getProxyTcpByDomain() -> IpInfo? {
        var ip: [CChar] = [CChar](repeating: 0, count: 128)
        var port: [CChar] = [CChar](repeating: 0, count: 40)
        
        var ipPointer = UnsafeMutablePointer<CChar>(&ip)
        var portPointer = UnsafeMutablePointer<CChar>(&port)
        
        let ret = Kiwi.server(toLocal: (appHost as NSString).utf8String, ipPointer, Int32(ip.count), portPointer, Int32(port.count))
        if ret == 0 {
            let ipStr = NSString(bytes: ip, length: Int(ip.count), encoding: NSASCIIStringEncoding)
            let portStr = NSString(bytes: port, length: Int(port.count), encoding: NSASCIIStringEncoding)
            
            self.apiUrl = ipStr as? String ?? ""
            self.port = Int(portStr?.intValue ?? 0)
            
            let ipInfo = IpInfo(ip: self.apiUrl, port: self.port)
            
            return ipInfo
        }
        
        return nil
    }

    deinit {
        
    }
    
}

struct IpInfo {
    let ip: String
    let port: Int
}



