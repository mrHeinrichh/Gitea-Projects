//
//  AppleMapViewFactory.swift
//  maps_flutter
//
//  Created by YUN WAH LEE on 16/1/24.
//

import Foundation
import UIKit
import Flutter

class AppleMapViewFactory : NSObject, FlutterPlatformViewFactory {
    
    var registrar: FlutterPluginRegistrar
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        self.registrar = registrar
        super.init()
    }
    
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let argsDictionary =  args as! Dictionary<String, Any>
        return AppleMapView(withRegistrar: registrar,withargs: argsDictionary,withId: viewId)
    }
}
