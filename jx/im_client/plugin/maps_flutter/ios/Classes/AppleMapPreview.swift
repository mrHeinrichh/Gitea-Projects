//
//  AppleMapPreview.swift
//  maps_flutter
//
//  Created by YUN WAH LEE on 17/1/24.
//

import Foundation

import Foundation
import MapKit
import Flutter

public class AppleMapPreview: NSObject, FlutterPlatformView {
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private var initialLocationSet = false
    private var pinAnnotation: MKPointAnnotation?
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var userCurrentCoordinate : CLLocationCoordinate2D?
    
    public init( withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any>) {
        let coordinate = args["coordinate"] as?  Dictionary<String, Double>
        let la = coordinate?["latitude"] as? Double
        let lo = coordinate?["longitude"] as? Double
        
        super.init()
        
        mapView.showsUserLocation = false
        mapView.showsCompass = false
        mapView.userTrackingMode = .none
        


        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: la!, longitude: lo!)
        mapView.addAnnotation(annotation)
        mapView.isUserInteractionEnabled = false
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: false)
    }
    

    public func view() -> UIView {
        return mapView
    }
    
    func setupButton(){
        let buttonItem = MKUserTrackingButton(mapView: mapView)
        buttonItem.layer.backgroundColor = UIColor(white: 1, alpha: 1).cgColor
        buttonItem.layer.cornerRadius = 5
        
        buttonItem.frame = CGRect(origin: CGPoint(x:5, y: 25), size: CGSize(width: 45, height: 45))

        mapView.addSubview(buttonItem)
        
        buttonItem.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            buttonItem.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -5),
            buttonItem.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 10),
            buttonItem.widthAnchor.constraint(equalToConstant: 45),
            buttonItem.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
}
