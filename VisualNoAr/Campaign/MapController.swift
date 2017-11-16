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
import FirebaseAuth

class MapController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    //MARK: Properties
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var topInfoContainer: UIView!
    @IBOutlet weak var imgStatus: UIImageView!
    @IBOutlet weak var txtAltitude: UILabel!
    @IBOutlet weak var txtLocation: UILabel!
    
    let locationManager = CLLocationManager()
    
    var brazil: MGLCoordinateBounds!
    var userRef, campaignRef: DatabaseReference!
    
    var previousRadian: Double! = 0.0
    var actualRadian: Double! = 0.0
    
    var geocoder: Geocoder!
    
    var latitude: Double!
    var longitude: Double!
    var altitude: Double!
    
    var timer: DispatchSourceTimer?
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.setContentInset(UIEdgeInsetsMake(topInfoContainer.frame.height * 1.4, 0, 0, 0), animated: false)
        
        topInfoContainer.setRadius(radius: 3)
        imgStatus.backgroundColor = UIColor(hexString: "#00E08A")
        imgStatus.setRadius(radius: 5.5)
        
        let ne = CLLocationCoordinate2D(latitude: 3.143108, longitude: -34.557192)
        let sw = CLLocationCoordinate2D(latitude: -35.237824, longitude: -61.368507)
        brazil = MGLCoordinateBounds(sw: sw, ne: ne)
        mapView.setVisibleCoordinateBounds(brazil, animated: false)
        
        geocoder = Geocoder.shared
        
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        print(user.uid)
        
        userRef = Database.database().reference(withPath: "user").child(user.uid)
        
        userRef.child("campaign").observe(DataEventType.value, with: { (snapshot) in
            let campaignId = snapshot.value as! Int
            
            self.campaignRef = Database.database().reference(withPath: "campaign").child(String(campaignId))
            self.campaignRef.child("active").observe(DataEventType.value, with: { (snapshot) in
                let active = snapshot.value as! Bool
                
                if active {
                    self.startListenLocation()
                    self.startTimer()
                } else {
                    self.stopLocationListener()
                    self.stopTimer()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func stopLocationListener() {
        campaignRef.removeAllObservers()
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
    
    private func showPlane() {
        var plane: MGLPointAnnotation
        
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        
        txtAltitude.text = String(format: "%.0fm", self.altitude)
        
        if mapView.annotations == nil {
            let plane = MGLPointAnnotation()
            plane.coordinate = coordinate
            
            mapView.setCenter(coordinate, zoomLevel: 13, animated: true)
            mapView.addAnnotation(plane)
        } else {
            plane = mapView.annotations?.first as! MGLPointAnnotation
            
            let previousCoordinate: CLLocationCoordinate2D = plane.coordinate
            
            self.setBearing(radian: previousCoordinate.bearingRadianTo(location: coordinate))
            
            plane.coordinate = coordinate
            
            mapView.setCenter(coordinate, zoomLevel: 13, animated: true)
        }
    }
    
    func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer!.schedule(deadline: .now(), repeating: .seconds(5))
        timer!.setEventHandler { [weak self] in
            self!.showLocationName()
        }
        timer!.resume()
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        self.stopTimer()
    }
    
    private func showLocationName() {
        guard let latitude = self.latitude, let longitude = self.longitude else {
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let options = ReverseGeocodeOptions(coordinate: coordinate)
        
        geocoder.geocode(options) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            
            self.txtLocation.text = placemark.administrativeRegion?.name ?? "Buscando localidade..."
            
            print(placemark)
        }
    }
    
    private func startListenLocation() {
        campaignRef.child("location").observe(.value, with: { (snapshot: DataSnapshot) in
            guard snapshot.hasChildren() else {
                return
            }
            
            let content = (snapshot.value as? NSDictionary)
            
            print(content!)
            
            self.latitude = content?["latitude"] as! Double
            self.longitude = content?["longitude"] as! Double
            self.altitude = content?["altitude"] as! Double
            
            self.showPlane()
        })
    }
    
    func setBearing(radian: Double) {
        previousRadian = actualRadian
        actualRadian = radian
    }
}
