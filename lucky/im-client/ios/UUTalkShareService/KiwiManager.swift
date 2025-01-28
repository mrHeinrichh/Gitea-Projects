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
let key = "JjEQafrhgEDaS0WAYdLSkBxRQnTDrCWHtXoSGH+23T0+f+Lb8S9FdTSFjlW8w2txXIDyk1NFk5LCIBn1jULnOSOCVGDDL8s18fomiIAgXC7Vdb1IiyJjN/0MDOj+Ujngmo1cfW3gLB3nI9dctGK8clG70ui+YgNLtfZPHuTuFIZ+PPj/lZGT5Y5+ZFWmdnM5QgHfXtRf+PKjXxY2q1IqLou0YDxvEzse9REUbmaIfMyXA0UsCrAOZs2sZCwP0hRjA1VwonRiJaXMtz6JeaRhPz5g9twZ+jvkbgQuj4mTpOd5+SLQVqq0huDZeABPDdsFXoZJtDsuePikH1Fbp02zbigLMIm0qQFBFjBfesoCYIiRkFxgnL9xKc3B0+3cThvov1GqXv0BAHBRZ6DjYDFWOmK0S0prqMI2ZOad9Au4+xG/fZexGSdPzHFJd9YuDCThocg1lnMNdbl8xwKKJA/latr8hu9PaUGbqlCy36SN6FzPdLvsVsVpMVEZUUtP/AxPtA9iTNgaqzRXOXBIZ6bDU8splI5GwBqKqfx7DW5A3mlP3x96RkhRHIuymPPpGsR8MUz2s4gYhZ2xOhpjiQkTClc9J90JMmDFpUYW55MG29MvXGbgfg1odonW44/aejZL+wvm8AXW882e5XycR+KR6QKKglSE/SBJKimbMBHzvosrJNO2ufxx9/jlCfTzJYo86M9VNOxTw1yrH4xWoYsnC7NwumnrythVtNB5C6UQCChJHVg7/RThiu3PwjLHtTw75wuPcWeTEe/NB3r+hnplrG9QEpou+1YbNWEQntnn5xElpCQQe34+/eB3yP5Su/jBJQO00yxCUnEUoQnhgtHOm0Ur4O/Ohp5YzwIgxyJn5bEV1851B7hYQwEiHF7ULjD0ikpN52S6tc48LrEjGV9haARasmO7EPjvV/zUWkR/vSWb6akDtAvl09Pa4LJ16Ft1j6kfhJvd/zJkTy8YboMqM9EaqHreqqD9l+Elfrlir6xTeXlyuQzjV/oviL75dR59mexudKMmxC5twGVpoPq7f+Zz4t+ZtL/6zbYvHlmHF+RM2y/z159UKH22Li9RRqYbWfTInOLrLlZ1l9WJelmz89pQD+nDR4toqxlT5ivZST0MU8/2LPGcU/x4vZiF/As5cSm3250SopoKJKeBqe3N9ntlJ6vMXoMknI9WTsMGvxcnA3BS2K0PLXAm9EACM852bWyf7gpX3ON9JW8PGDTGvwlqe9mitrz3SRgQs6CJGCQyikNjZrR5W0LxCWk3wijYxSIzA2TAP7DmPbyPcTGs00le19+pmbr9DYiohDaZFV8/E/uFosSFDy7BfBe8Bm9+amc8UHx0Nx1W4XMz6BZpcoMdztJOJUI+RJ9TlCyOzoyDLTvM2YEOUgsbBcajjsBNXsgs4DrG0zHEgs2P+cPmDMZPA5EbZ3hX0D9swT3qMLjWBf1Wehmn94ZebbsmVA5x5hkW6gVJ2Nh2DeyFAgOADFSt4s94yB3W2mijt/2lUqB60JezKEincL2qzcbNvy0YR55LdFFBmaSfpamO8ZU9/uXpxYPhu4gVAB1Oub/y6L/czRzz9gXhb+n0ULxVWlYoo+I7Kv+Dzw0Re1r1ecYpLWmz6yLszgwyLHMt81KFJAr8lvbySxzrXm+ZUKp67IF3Uh+COtGzthDFRNoMx/ULHaPomWYiXJiDfop8W2dU092VHKuyB83ACNSFtKbd3wbCJSCxQ0UENpVAnp22u18qtUh6j7pET/Z6sTml6xIZj+ezjFbLvva3G1a+mceVs7t3kQwfrLYpx2G85a+UD2rQ2ntpHorcE6L9Yb/Dwi6Pwqv4GL6+1Pi3egIro7Y1j6tv7dwT5/womvZ3YerEb7JitOxvpMgpCIWRgFxmS6exNw3eNw6jc/Ow+NvYOu01WF2RxvkhpmLbMxqmpTCrvKJaIw=="

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



