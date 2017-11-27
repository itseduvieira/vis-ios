//
//  MapController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 19/08/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Mapbox
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
    
    var latitude: Double!
    var longitude: Double!
    var altitude: Double!
    var location: String!
    
    var annotationView: PlaneAnnotationView?
    
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
                } else {
                    self.stopLocationListener()
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
        
        annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "plane") as? PlaneAnnotationView
        
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
        txtLocation.text = self.location
        
        if mapView.annotations == nil {
            let plane = MGLPointAnnotation()
            plane.coordinate = coordinate
            
            mapView.addAnnotation(plane)
            mapView.setCenter(coordinate, zoomLevel: 11, animated: false)
        } else {
            let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 4200, pitch: 15, heading: 0)
            mapView.setCamera(camera, withDuration: 8, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            plane = mapView.annotations?.first as! MGLPointAnnotation
            
            let previousCoordinate: CLLocationCoordinate2D = plane.coordinate
            
            annotationView?.rotate(radians: previousCoordinate.bearingRadianTo(location: coordinate))
            
            plane.coordinate = coordinate
        }
    }
    
    private func startListenLocation() {
        campaignRef.child("location").observe(.value, with: { (snapshot: DataSnapshot) in
            guard snapshot.hasChildren() else {
                return
            }
            
            let content = (snapshot.value as? NSDictionary)
            
            let newLat = content?["latitude"] as! Double
            let newLon = content?["longitude"] as! Double
            let newAlt = content?["altitude"] as! Double
            
            if newLat == self.latitude &&
                newLon == self.longitude &&
                    newAlt == self.altitude {
                return
            }
            
            print(content!)
            print("---")
            
            self.latitude = newLat
            self.longitude = newLon
            self.altitude = newAlt
            
            if let location = content?["description"] as? String {
                self.location = location
            }
            
            self.showPlane()
        })
    }
    
    @IBAction func center() {
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        
        let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 4200, pitch: 15, heading: 0)
        mapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
}
