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
import PromiseKit

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
    
    var campaign: Campaign!
    
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
        
        listenCampaign()
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
            
            detailVC.campaign = self.campaign
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
        let menuItem = UIBarButtonItem(image: UIImage(named: "IconMenu"), style: .plain,target: self, action: #selector(openMenu))
        navItem.leftBarButtonItem = menuItem
        let placeItem = UIBarButtonItem(image: UIImage(named: "IconPlace"), style: .plain,target: self, action: #selector(center))
        navItem.rightBarButtonItem = placeItem
        
        if let company = UserDefaults.standard.string(forKey: "company") {
            self.navBar.topItem?.title = company
        }
    }
    
    func setNavigationDrawer() {
        options.navigationDrawerType = .LeftDrawer
        options.navigationDrawerOpenDirection = .LeftEdge
        options.navigationDrawerWidth = UIScreen.main.bounds.width - 60
        
        navigationDrawer.setup(withOptions: options)
        let menuVC = self.storyboard?.instantiateViewController(withIdentifier: "DrawerMenuViewController") as! DrawerMenuController
        navigationDrawer.setNavigationDrawerController(viewController: menuVC)
        navigationDrawer.delegate = self
    }
    
    @objc func openMenu() {
        NavigationDrawer.sharedInstance.toggleNavigationDrawer(completionHandler: nil)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        //listenCampaign()
    }
    
    func listenCampaign() {
        let user = Auth.auth().currentUser
        userRef = Database.database().reference(withPath: "user").child(user!.uid)
        userRef.child("campaign").observe(DataEventType.value, with: { (snapshot) in
            if let campaignId = snapshot.value as? String {
                
                let storage = Storage.storage()
                let refBand = storage.reference().child("campaigns/\(campaignId)/band.jpeg")

                refBand.getData(maxSize: 8 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        self.campaign.band = data!
                    }
                }
                
//                let refPic1 = storage.reference().child("campaigns/\(campaignId)")
//
//                refPic1.getData(maxSize: 8 * 1024 * 1024) { data, error in
//                    if let error = error {
//                        print(error)
//                    } else {
//                        self.pic1 = data!
//                    }
//                }
//
//                let refPic2 = storage.reference().child("campaigns/\(campaignId)")
//
//                refPic2.getData(maxSize: 8 * 1024 * 1024) { data, error in
//                    if let error = error {
//                        print(error)
//                    } else {
//                        self.pic2 = data!
//                    }
//                }
//
//                let refPic3 = storage.reference().child("campaigns/\(campaignId)")
//
//                refPic3.getData(maxSize: 8 * 1024 * 1024) { data, error in
//                    if let error = error {
//                        print(error)
//                    } else {
//                        self.pic3 = data!
//                    }
//                }
                
                self.btnDetail.isEnabled = true
                
                self.campaignRef = Database.database().reference(withPath: "campaign").child(campaignId)
                self.campaignRef.observe(DataEventType.value, with: { (snapshot) in
                    let cDict = snapshot.value as? [String : AnyObject] ?? [:]
                    
                    self.txtCampaign.text = (cDict["name"] as? String)?.uppercased()
                    self.txtPrefix.text = (cDict["plane"] as? String)?.uppercased()
                    self.txtPlace.text = (cDict["place"] as? String)?.uppercased()
                    
                    self.campaign = Campaign()
                    self.campaign.id = campaignId
                    self.campaign.name = cDict["name"] as? String
                    self.campaign.plane = cDict["plane"] as? String
                    self.campaign.place = Place()
                    self.campaign.place.title = cDict["place"] as? String
                    
                    firstly {
                        DataAccess.instance.getPlace(cDict["placeId"] as! String)
                    }.done { place in
                        self.campaign.place = place
                        
                        firstly {
                            DataAccess.instance.getImage(place.urls[0]["url"]!)
                        }.done { data in
                            self.campaign.place.pic1 = data
                        }.catch { error in
                            print(error)
                        }
                        
                        firstly {
                            DataAccess.instance.getImage(place.urls[1]["url"]!)
                        }.done { data in
                            self.campaign.place.pic2 = data
                        }.catch { error in
                            print(error)
                        }
                        
                        firstly {
                            DataAccess.instance.getImage(place.urls[2]["url"]!)
                        }.done { data in
                            self.campaign.place.pic3 = data
                        }.catch { error in
                            print(error)
                        }
                    }.catch { error in
                        print(error)
                        
                        self.campaign.place = Place()
                    }
                    
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
    
    @objc func center() {
        if self.latitude != nil, self.longitude != nil {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            
            let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 4200, pitch: 15, heading: 0)
            mapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        } else {
            let center = CLLocationCoordinate2D(latitude: -15.77972, longitude: -47.92972)
            
            if distance(from: mapView.centerCoordinate, to: center) > 900000 {
                let ne = CLLocationCoordinate2D(latitude: 3.143108, longitude: -34.557192)
                let sw = CLLocationCoordinate2D(latitude: -35.237824, longitude: -61.368507)
                brazil = MGLCoordinateBounds(sw: sw, ne: ne)
                mapView.setVisibleCoordinateBounds(brazil, animated: true)
            } else {
                let distance: CLLocationDistance = 10000000
                
                let camera = MGLMapCamera(lookingAtCenter: center, fromDistance: distance, pitch: 0, heading: 0)
                mapView.setCamera(camera, withDuration: 2.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            }
        }
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}

