//
//  BatteryMgr.swift
//  Runner
//
//  Created by Venus Heng on 16/7/24.
//

import Foundation

public class BatteryMgr: NSObject {
    let methodChannel: FlutterMethodChannel?
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
        setupConfg()
    }
    
    func setupConfg(){
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    @objc func batteryLevelDidChange(_ notification: NSNotification) {
        let batteryLevel = UIDevice.current.batteryLevel * 100
        self.methodChannel?.invokeMethod("batteryLevel", arguments: [
            "level": Int(batteryLevel)
        ])
        NSLog("BatteryLevelChanged: \(batteryLevel) \(batteryLevel * 100)%%")
    }
        
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
   }
}
