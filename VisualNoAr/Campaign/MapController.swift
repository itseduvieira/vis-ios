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
import FirebaseStorage

class MapController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, NavigationDrawerDelegate {
    
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
    
    let options = NavigationDrawerOptions()
    
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
    
    let navigationDrawer = NavigationDrawer.sharedInstance
    
    var annotationView: PlaneAnnotationView?
    
    var userRef, campaignRef: DatabaseReference!
    var active: Bool!
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {}
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        setMapConfig()
        
        setNavigationDrawer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NavigationDrawer.sharedInstance.initialize(forViewController: self)
        
        //listenCampaign()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        if self.campaignRef != nil {
//            self.campaignRef.removeAllObservers()
//        }
//        self.userRef.removeAllObservers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueMapToDetail" {
            let detailVC = segue.destination as! DetailController
            
            detailVC.id = self.id
            detailVC.name = self.name
            detailVC.plane = self.plane
            detailVC.place = self.place
        }
    }
    
    func setMapConfig() {
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
    
    func setNavigationBar() {
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        let calendarTypeItem = UIBarButtonItem(image: UIImage(named: "IconMenu"), style: .plain,target: self, action: #selector(openMenu))
        navItem.leftBarButtonItem = calendarTypeItem
    }
    
    func setNavigationDrawer() {
        options.navigationDrawerType = .LeftDrawer
        options.navigationDrawerOpenDirection = .LeftEdge
        
        navigationDrawer.setup(withOptions: options)
        let menuVC = self.storyboard?.instantiateViewController(withIdentifier: "DrawerMenuViewController") as! DrawerMenuController
        navigationDrawer.setNavigationDrawerController(viewController: menuVC)
        navigationDrawer.delegate = self
    }
    
    @objc func openMenu() {
        NavigationDrawer.sharedInstance.toggleNavigationDrawer(completionHandler: nil)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        listenCampaign()
    }
    
    func listenCampaign() {
        let user = Auth.auth().currentUser
        userRef = Database.database().reference(withPath: "user").child(user!.uid)
        userRef.child("campaign").observe(DataEventType.value, with: { (snapshot) in
            if let campaignId = snapshot.value as? String {
                
                let storage = Storage.storage()
                let ref = storage.reference().child("campaigns/\(campaignId)")

//                ref.getData(maxSize: 8 * 1024 * 1024) { data, error in
//                    if let error = error {
//                        print(error)
//
//                    } else {
//                        //pdcUser.picture = data!
//
//                    }
//                }
                
                self.btnDetail.isEnabled = true
                
                self.campaignRef = Database.database().reference(withPath: "campaign").child(campaignId)
                self.campaignRef.observe(DataEventType.value, with: { (snapshot) in
                    let cDict = snapshot.value as? [String : AnyObject] ?? [:]
                    
                    self.txtCampaign.text = cDict["name"] as? String
                    self.txtPrefix.text = cDict["plane"] as? String
                    self.txtPlace.text = cDict["place"] as? String
                    
                    self.id = campaignId
                    self.name = cDict["name"] as? String
                    self.plane = cDict["plane"] as? String
                    self.place = cDict["place"] as? String
                    
                    self.active = cDict["active"] as! Bool
                    
                    if self.active {
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
                        self.campaignRef.removeAllObservers()
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            } else {
                self.presentLargeAlert(self, { })
            }
        }) { (error) in
            print(error.localizedDescription)
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
    
    @IBAction func center() {
        if self.latitude != nil, self.longitude != nil {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            
            let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 4200, pitch: 15, heading: 0)
            mapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
    }
}

