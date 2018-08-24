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

class MapController: UIViewController, MGLMapViewDelegate, NavigationDrawerDelegate {
    
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
    
    var brazil: MGLCoordinateBounds!
    
    var timer: Timer!
    var camera: MGLMapCamera!
    var position: CLLocationCoordinate2D!
    var altitude: Double!
    var location: String!
    
    let navigationDrawer = NavigationDrawer.sharedInstance
    
    var userRef, campaignRef: DatabaseReference!
    var active = false
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {}
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        setMapConfig()
        
        setNavigationDrawer()
        
        listenCampaign()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if self.active {
            startTimer()
        }
        
        NavigationDrawer.sharedInstance.initialize(forViewController: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTimer()
        
//        if self.campaignRef != nil {
//            self.campaignRef.removeAllObservers()
//        }
//        self.userRef.removeAllObservers()
    }
    
    @objc func runTimedCode() {
        print("ticking: \(position!.latitude),\(position!.longitude) ")
        
        mapView.setContentInset(UIEdgeInsetsMake(156, 0, 28, 0), animated: true)
        
        camera.centerCoordinate = position
        
//        let point = MGLPointAnnotation()
//        point.coordinate = position
//        mapView.addAnnotation(point)
        
        mapView.setCamera(camera, withDuration: 2.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
    }
    
    func startTimer() {
        print("start timer...")
        
        timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        print("stop timer")
        
        if timer != nil {
            timer.invalidate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueMapToDetail" {
            let detailVC = segue.destination as! DetailController
            
            detailVC.campaign = self.campaign
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
        let reuseIdentifier = "reusableDotView"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
            annotationView?.layer.borderWidth = 4.0
            annotationView?.layer.borderColor = UIColor.white.cgColor
            annotationView!.backgroundColor = UIColor(red:0.03, green:0.80, blue:0.69, alpha:1.0)
        }
        
        return annotationView
    }
    
    func setMapConfig() {
        mapView.delegate = self
        
        let ne = CLLocationCoordinate2D(latitude: 3.143108, longitude: -34.557192)
        let sw = CLLocationCoordinate2D(latitude: -35.237824, longitude: -61.368507)
        let brazil = MGLCoordinateBounds(sw: sw, ne: ne)
        mapView.setVisibleCoordinateBounds(brazil, animated: false)
        
        position = mapView.centerCoordinate
        camera = MGLMapCamera(lookingAtCenter: position, fromDistance: 1000 * 500, pitch: 45, heading: 0)
//        mapView.setCamera(camera, withDuration: 2.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        
        topInfoContainer.setRadius(radius: 3)
        imgStatus.backgroundColor = UIColor(hexString: "#00E08A")
        imgStatus.setRadius(radius: 5.5)
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
    
    func listenCampaign() {
        let user = Auth.auth().currentUser
        userRef = Database.database().reference(withPath: "user").child(user!.uid)
        userRef.child("campaign").observe(DataEventType.value, with: { (snapshot) in
            if let campaignId = snapshot.value as? String {
                
                let storage = Storage.storage()
                let refBand = storage.reference().child("campaigns/\(campaignId)/band.*")

                refBand.getData(maxSize: 8 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        self.campaign.band = data!
                    }
                }
                
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
                        
                        print(locDict)
                        print("---")
                        
                        self.position = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
                        self.altitude = newAlt
                        
                        if let location = locDict["description"] as? String {
                            self.location = location
                        }
                        
                        self.showPlane()
                    } else {
                        self.position = nil
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
    
    private func showPlane() {
        txtAltitude.text = String(format: "%.0fm", self.altitude)
        txtLocation.text = self.location
        
        //self.plane.isHidden = false
        
        startTimer()
    }
    
    @objc func center() {
        if self.position != nil {
            camera.centerCoordinate = self.position
            mapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        } else {
            setMapConfig()
        }
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}

