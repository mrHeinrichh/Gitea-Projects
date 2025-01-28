//
//  AppleMapView.swift
//  maps_flutter
//
//  Created by YUN WAH LEE on 16/1/24.
//

import Foundation
import MapKit
import Flutter

public class AppleMapView: NSObject, FlutterPlatformView {
    
    var channel: FlutterMethodChannel
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private var initialLocationSet = false
    private var pinAnnotation: MKPointAnnotation?
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var userCurrentCoordinate : CLLocationCoordinate2D?
    
    public init( withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any>, withId id: Int64) {
        self.channel = FlutterMethodChannel(name: "map_view_flutter/\(id)", binaryMessenger: registrar.messenger())
        let coordinate = args["coordinate"] as?  Dictionary<String, Double>
        let la = coordinate?["latitude"] as? Double
        let lo = coordinate?["longitude"] as? Double
        let isUserInteractionEnabled = coordinate?["isUserInteractionEnabled"] as? Bool ?? true
        let isZoomEnabled = coordinate?["isZoomEnabled"] as? Bool ?? true
        
        print("data ::\(args)")
        if(coordinate != nil){
            initialLocationSet = true
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: la!, longitude: lo!)
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: false)
        }
        super.init()
        
        self.setMethodCallHandlers()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.showsCompass = false
        mapView.isUserInteractionEnabled = isUserInteractionEnabled
        mapView.isZoomEnabled = false
        
        setupButton()

//         panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleMapPan(_:)))
//         mapView.addGestureRecognizer(panGestureRecognizer)
    }
    

    public func view() -> UIView {
        return mapView
    }
    
    private func setMethodCallHandlers() {
            channel.setMethodCallHandler({ [unowned self] (call: FlutterMethodCall, result: @escaping FlutterResult)  -> Void in
                if let args: Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                    switch(call.method) {
                    case "getCurrentUserCoordinate":
                        let coordinateDictionary: [String: String] = [
                            "latitude": String(self.userCurrentCoordinate!.latitude),
                            "longitude": String(self.userCurrentCoordinate!.longitude)
                        ]
                        result(coordinateDictionary)
                        break
                    case "getAddress":
                        print(args)
                        let la = args["latitude"] as? Double ?? self.userCurrentCoordinate!.latitude
                        let lo = args["longitude"] as? Double ?? self.userCurrentCoordinate!.longitude
                        
                        let geocoder = CLGeocoder()
                        geocoder.reverseGeocodeLocation(CLLocation(latitude: la, longitude: lo)) { (placemarks, error) in
                            if let error = error {
                                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                                return
                            }

                            if let placemark = placemarks?.first {
                                let address: [String: String] = [
                                    "name": placemark.name ?? "",
                                    "address": placemark.name ?? "",
                                    "city": placemark.locality ?? "",
                                    "state": placemark.administrativeArea ?? "",
                                    "country": placemark.country ?? "",
                                    "postalCode": placemark.postalCode ?? ""
                                ]
                                
                                result(address)
                            } else {
                                result({})
                            }
                        }
                        break
                    case "getNearbyLocation":
                        if #available(iOS 14.0, *) {
                            if (userCurrentCoordinate == nil) {
                                result(nil)
                                return
                            }
                           let request: MKLocalPointsOfInterestRequest = .init(center: userCurrentCoordinate!, radius: 1000)
                            request.pointOfInterestFilter = .init(excluding: [.restroom])
//                             let request = MKLocalSearch.Request()
//                             request.naturalLanguageQuery = "place"
//                             request.region = mapView.region
                            let search = MKLocalSearch(request: request)
                            search.start { (response, error) in
                                if let response = response {
                                    let mapItems = response.mapItems
                                    let resultArray = mapItems.map { mapItem -> [String: Any]? in
                                        print(mapItem)
                                        print(mapItem.pointOfInterestCategory)

                                        let region = mapItem.placemark.region as? CLCircularRegion
                                        guard let pointOfInterestCategory = mapItem.pointOfInterestCategory else {
                                               return nil
                                           }
                                        var itemDictionary: [String: Any] = [:]
                                        itemDictionary["name"] = mapItem.name
                                        itemDictionary["address"] = mapItem.placemark.title
                                        itemDictionary["category"] = mapItem.pointOfInterestCategory ?? ""
                                        itemDictionary["latitude"] = mapItem.placemark.coordinate.latitude
                                        itemDictionary["longitude"] = mapItem.placemark.coordinate.longitude
                                        itemDictionary["longitude"] = mapItem.placemark.coordinate.longitude
                                        itemDictionary["distance"] = region?.radius ?? 0
                                        return itemDictionary
                                    }
                                    let filteredResultArray = resultArray.compactMap { $0 }

                                    result(filteredResultArray)
                                } else if error != nil {
                                    result(nil)
                                }
                            }
                        }
                        break
                    case "pinLocation":
                        let la = args["la"] as? Double
                        let lo = args["lo"] as? Double
                        mapView.removeAnnotation(pinAnnotation!)

                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: la!, longitude: lo!)
                        mapView.addAnnotation(annotation)
                        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                        mapView.setRegion(region, animated: true)
                        pinAnnotation = annotation

                        break
                    case "annotationLocation":
                        let coordinateDictionary: [String: String] = [
                            "latitude": String(self.pinAnnotation!.coordinate.latitude),
                            "longitude": String(self.pinAnnotation!.coordinate.longitude)
                        ]
                        result(coordinateDictionary)
                        break
                    case "snapshot":
                            let pixel = args["data"]
                            let width = args["width"] as? Double ?? 400
                            let height = args["height"] as? Double ?? 200
                        snapshotCurrentAnnotations(width: width,height: height ,onCompletion: { (snapshot: FlutterStandardTypedData?, error: Error?) -> Void in
                            result(snapshot ?? error)})
//                             if let flutterTypedData = pixel as? FlutterStandardTypedData {
//                                 // Access the byte array
//                                 let uint8Array = flutterTypedData.data
//                                 // Now uint8Array is a [UInt8] containing the data
//

//                            } else {
//                                print("Invalid FlutterStandardTypedData")
//                            }
                        break
                    case "focus":
                        let la = args["la"] as? Double
                        let lo = args["lo"] as? Double
                        
                        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: la!, longitude: lo!), latitudinalMeters: 500, longitudinalMeters: 500)
                        mapView.setRegion(region, animated: true)
                        break
                    default:
                        result(FlutterMethodNotImplemented)
                        break
                    }
                }
            })
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

    func snapshotCurrentAnnotations(width : Double,height:Double, onCompletion: @escaping (FlutterStandardTypedData?, Error?) -> Void){
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: pinAnnotation!.coordinate,latitudinalMeters: 500, longitudinalMeters: 500)
        options.size = CGSize(width: width, height: height)
        print(mapView.frame.size)
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error taking snapshot: \(error.debugDescription)")
                onCompletion(nil, error)
                return
            }

            let image = UIGraphicsImageRenderer(size: options.size).image { _ in
                snapshot.image.draw(at: .zero)

                // Use a default pin image for annotations
                if let pinImage = UIImage(named: "pin_img") {
                    let point = snapshot.point(for: self.pinAnnotation!.coordinate)
                    let rect = CGRect(origin: point, size: CGSize(width: 30, height: 38)) // Adjust the size as needed
                    pinImage.draw(in: rect)
                } else {
                    print("Error: Pin image is nil.")
                }
            }

            // Convert the image to FlutterStandardTypedData
            if let imageData = image.pngData() {
                onCompletion(FlutterStandardTypedData.init(bytes: imageData), nil)
            }
        }
    }
    
    @objc func handleMapPan(_ gestureRecognizer: UIPanGestureRecognizer) {
            // Update the pin's coordinate continuously during the pan gesture
            if gestureRecognizer.state == .changed {
                if let annotation = pinAnnotation {
                    let point = gestureRecognizer.location(in: mapView)
                    let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                    annotation.coordinate = coordinate
                }
            }
        }
    
    private func addPin(at coordinate: CLLocationCoordinate2D) {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            pinAnnotation = annotation
        }
}

extension AppleMapView : CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.global().async { [self] in
          if CLLocationManager.locationServicesEnabled() {
              userCurrentCoordinate = location.coordinate
              if !initialLocationSet {
                  let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                  mapView.setRegion(region, animated: true)
                  initialLocationSet = true
                  
                  addPin(at: location.coordinate)
              }
          }
        }
        
        
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.global().async { [self] in
          if CLLocationManager.locationServicesEnabled() {
              if #available(iOS 14.0, *) {
                  print(manager.authorizationStatus.rawValue)
                  if(manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted){
                      channel.invokeMethod("getPermission", arguments: false)
                  }else{
                      self.channel.invokeMethod("getPermission", arguments: true)
                  }
              } else {
                  // Fallback on earlier versions
              }
          }
        }
        
    }
}

extension AppleMapView : MKMapViewDelegate {
//     public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//         if let annotation = pinAnnotation {
//             annotation.coordinate = mapView.centerCoordinate
//         }
//    }

    public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool){
        if(mode == .none){
        print(".folow is call pin event")
            if let location = mapView.userLocation.location {
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                mapView.setRegion(region, animated: true)
                if(pinAnnotation != nil){
                    mapView.removeAnnotation(pinAnnotation!)
                    addPin(at: location.coordinate)
                }
                
                let coordinateDictionary: [String: String] = [
                    "latitude": String(location.coordinate.latitude),
                    "longitude": String(location.coordinate.longitude)
                ]
                channel.invokeMethod("pinCurrentLocation", arguments:coordinateDictionary)
            }
        }
    }
}
