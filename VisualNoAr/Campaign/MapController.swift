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
    @IBOutlet weak var txtCampaign: UILabel!
    @IBOutlet weak var txtPrefix: UILabel!
    @IBOutlet weak var txtPlace: UILabel!
    @IBOutlet weak var btnDetail: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    
    var id: String!
    var name: String!
    var place: String!
    var plane: String!
    
    let locationManager = CLLocationManager()
    
    var brazil: MGLCoordinateBounds!
    
    var latitude: Double!
    var longitude: Double!
    var altitude: Double!
    var location: String!
    
    var annotationView: PlaneAnnotationView?
    
    var userRef: DatabaseReference!
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {}
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueDetail" {
            let destination = segue.destination as! DetailController
            destination.id = self.id
            destination.name = self.name
            destination.plane = self.plane
            destination.place = self.place
        }
    }
    
    func setNavigationBar() {
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        let calendarTypeItem = UIBarButtonItem(image: UIImage(named: "IconMenu"), style: .plain,target: self, action: #selector(openMenu))
        navItem.leftBarButtonItem = calendarTypeItem
    }
    
    @objc func openMenu() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.drawerController.setDrawerState(.opened, animated: true)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        guard let user = Auth.auth().currentUser else {
            print("Error getting user after mapView loaded")
            
            return
        }
        
        if userRef == nil {
            userRef = Database.database().reference(withPath: "user").child(user.uid)
            
            userRef.child("campaign").observe(DataEventType.value, with: { (snapshot) in
                if let campaignId = snapshot.value as? String {
                    let campaignRef = Database.database().reference(withPath: "campaign").child(campaignId)
                    
                    self.btnDetail.isEnabled = true
                    
                    campaignRef.observe(DataEventType.value, with: { (snapshot) in
                        let cDict = snapshot.value as? [String : AnyObject] ?? [:]
                        
                        self.txtCampaign.text = cDict["name"] as? String
                        self.txtPrefix.text = cDict["plane"] as? String
                        self.txtPlace.text = cDict["place"] as? String
                        
                        self.id = campaignId
                        self.name = cDict["name"] as? String
                        self.plane = cDict["plane"] as? String
                        self.place = cDict["place"] as? String
                        
                        let active = cDict["active"] as! Bool
                        
                        if active {
                            let locDict = cDict["location"] as! [String : AnyObject]
                            let newLat = locDict["latitude"] as! Double
                            let newLon = locDict["longitude"] as! Double
                            let newAlt = locDict["altitude"] as! Double
                            
                            if newLat == self.latitude &&
                                newLon == self.longitude {
                                return
                            }
                            
                            print(locDict)
                            print("---")
                            
                            self.latitude = newLat
                            self.longitude = newLon
                            self.altitude = newAlt
                            
                            if let location = locDict["description"] as? String {
                                self.location = location
                            }
                            
                            self.showPlane()
                        } else {
                            self.stopListenLocation(campaignRef)
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
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
            
            //annotationView?.rotate(radians: previousCoordinate.bearingRadianTo(location: coordinate))
            
            plane.coordinate = coordinate
        }
    }
    
    private func stopListenLocation(_ campaignRef: DatabaseReference) {
        campaignRef.removeAllObservers()
    }
    
//    private func startListenLocation(_ campaignRef: DatabaseReference) {
//        campaignRef.child("location").observe(.value, with: { (snapshot: DataSnapshot) in
//            guard snapshot.hasChildren() else {
//                return
//            }
//
//            let content = (snapshot.value as? NSDictionary)
//
//            let newLat = content?["latitude"] as! Double
//            let newLon = content?["longitude"] as! Double
//            let newAlt = content?["altitude"] as! Double
//
//            if newLat == self.latitude &&
//                newLon == self.longitude &&
//                    newAlt == self.altitude {
//                return
//            }
//
//            print(content!)
//            print("---")
//
//            self.latitude = newLat
//            self.longitude = newLon
//            self.altitude = newAlt
//
//            if let location = content?["description"] as? String {
//                self.location = location
//            }
//
//            self.showPlane()
//        })
//    }
    
    @IBAction func center() {
        if self.latitude != nil, self.longitude != nil {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            
            let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 4200, pitch: 15, heading: 0)
            mapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
    }
}
