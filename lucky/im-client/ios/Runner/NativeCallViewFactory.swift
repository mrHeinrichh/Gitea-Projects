//
//  NativeCallViewFactory.swift
//  Runner
//
//  Created by YUN WAH LEE on 28/2/24.
//

import Foundation
import Flutter

class NativeCallViewFactory : NSObject, FlutterPlatformViewFactory {
    
    var agoraCallManager: AgoraCallManager
    
    public init(agoraCallManager manager: AgoraCallManager){
        self.agoraCallManager = manager
        super.init()
    }
    
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let argsDictionary =  args as! Dictionary<String, Any>
        return NativeCallView(agoraCallManager: agoraCallManager ,withargs: argsDictionary,withId: viewId)
    }
}
