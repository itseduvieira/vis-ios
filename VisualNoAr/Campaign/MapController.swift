//
//  MapController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 19/08/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder
import FirebaseDatabase

class MapController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    //MARK: Properties
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var topInfoContainer: UIView!
    @IBOutlet weak var imgStatus: UIImageView!
    @IBOutlet weak var txtAltitude: UILabel!
    
    let locationManager = CLLocationManager()
    
    var brazil: MGLCoordinateBounds!
    var ref: DatabaseReference!
    
    var previousRadian: Double! = 0.0
    var actualRadian: Double! = 0.0
    
    var geocoder: Geocoder!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference(withPath: "/campaign/1")
        
        mapView.delegate = self
        mapView.setContentInset(UIEdgeInsetsMake(topInfoContainer.frame.height * 1.4, 0, 0, 0), animated: false)
        
        topInfoContainer.setRadius(radius: 3)
        imgStatus.backgroundColor = UIColor(hexString: "#00E08A")
        imgStatus.setRadius(radius: 5.5)
        
        let ne = CLLocationCoordinate2D(latitude: 3.143108, longitude: -34.557192)
        let sw = CLLocationCoordinate2D(latitude: -35.237824, longitude: -61.368507)
        brazil = MGLCoordinateBounds(sw: sw, ne: ne)
        mapView.setVisibleCoordinateBounds(brazil, animated: false)
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let dictRoot = NSDictionary(contentsOfFile: path)
            if let dict = dictRoot {
                geocoder = Geocoder(accessToken: dict["MGLMapboxAccessToken"] as? String)
            }
        }
        
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        listenPlaneLocation()
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "plane") as? PlaneAnnotationView
        
        if annotationView == nil {
            annotationView = PlaneAnnotationView(reuseIdentifier: "plane", image: UIImage(named: "Plane")!)
            annotationView!.controller = self
        }
        
        return annotationView
    }
    
    private func showPlane(latitude: Double, longitude: Double, altitude: Double) {
        var plane: MGLPointAnnotation
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        txtAltitude.text = String(format: "%.0fm", altitude)
        
        if mapView.annotations == nil {
            let plane = MGLPointAnnotation()
            plane.coordinate = coordinate
            
            mapView.setCenter(coordinate, zoomLevel: mapView.zoomLevel + 2, animated: true)
            mapView.addAnnotation(plane)
        } else {
            plane = mapView.annotations?.first as! MGLPointAnnotation
            
            let previousCoordinate: CLLocationCoordinate2D = plane.coordinate
            
            self.setBearing(radian: previousCoordinate.bearingRadianTo(location: coordinate))
            
            let options = ReverseGeocodeOptions(coordinate: previousCoordinate)
            geocoder.geocode(options) { (placemarks, attribution, error) in
                guard let placemark = placemarks?.first else {
                    return
                }
                
                print(placemark.administrativeRegion?.name ?? "")
                // New York
                print(placemark.administrativeRegion?.neighborhood ?? "")
                // US-NY
            }
            
            plane.coordinate = coordinate
        }
    }
    
    private func listenPlaneLocation() {
        ref.observe(.value, with: { (snapshot: DataSnapshot) in
            guard snapshot.hasChildren() else {
                return
            }
            
            let content = (snapshot.value as? NSDictionary)
            
            print(content!)
            
            let latitude = content?["latitude"] as! Double
            let longitude = content?["longitude"] as! Double
            let altitude = content?["altitude"] as! Double
            
            self.showPlane(latitude: latitude, longitude: longitude, altitude: altitude)
        })
    }
    
    func setBearing(radian: Double) {
        previousRadian = actualRadian
        actualRadian = radian
    }
}
