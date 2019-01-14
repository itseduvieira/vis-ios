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
    @IBOutlet weak var imgPlane: UIImageView!
    @IBOutlet weak var txtStatus: UILabel!
    @IBOutlet weak var mapHandler: UIView!
    
    let navigationDrawer = NavigationDrawer.sharedInstance
    
    var campaign: Campaign!
    var timer: Timer!
    var camera: MGLMapCamera!
    var posQueue: Queue<VisLocation>!
    var distance: CLLocationDistance = 1000
    
    var point: MGLPointAnnotation!
    
    var userRef, campaignRef: DatabaseReference!
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {}
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        setNavigationBar()
        
        setNavigationDrawer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NavigationDrawer.sharedInstance.initialize(forViewController: self)
        
        listenCampaign()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTimer()
        
        releaseListeners()
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        self.mapView = mapView
        
        setMapConfig()
    }
    
    func setMapConfig() {
        //        let tap = UITapGestureRecognizer(target: self, action: Selector("followTrip:"))
        //        bigButton.addGestureRecognizer(tap)
        
        self.centerMap()
        
        topInfoContainer.setRadius(radius: 3)
        imgStatus.backgroundColor = UIColor(hexString: "#00E08A")
        imgStatus.setRadius(radius: 5.5)
        
        txtStatus.text = "Status"
        txtLocation.text = "Aguardando campanha..."
    }
    
    func centerMap() {
        mapView.setContentInset(UIEdgeInsetsMake(topInfoContainer.frame.height + navBar.frame.height, 0, 0, 0), animated: true)
        
        let coordinate = CLLocationCoordinate2D(latitude: -20.0, longitude: -47.8825)

        camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 13000 * 1000, pitch: 0, heading: 0)
        
        mapView.fly(to: camera, withDuration: 2, completionHandler: { })
    }
    
    func releaseListeners() {
        self.userRef.removeAllObservers()
        if self.campaignRef != nil {
            self.campaignRef.removeAllObservers()
            self.campaignRef.child("active").removeAllObservers()
            self.campaignRef.child("location").removeAllObservers()
        }
    }
    
    func checkCampaignStatus() -> VisLocation? {
        guard let nextLoc = self.posQueue.dequeue() else {
            if campaign == nil {
                self.presentLargeAlert(self, {
                    self.clear()
                })
                
                self.btnDetail.isEnabled = false
            } else if !campaign.active {
                let alert = UIAlertController(title: "Campanha Encerrada", message: "Sua campanha acabou de ser exibida com sucesso!", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.txtLocation.text = "Aguardando decolagem..."
                    
                    self.clear()
                }))
                
                self.present(alert, animated: true, completion: {
                    self.stopTimer()
                })
            }
            
            return nil
        }
        
        return nextLoc
    }
    
    @objc func runTimedCode() {
        guard let nextLoc = self.checkCampaignStatus() else {
            return
        }
        
        if point == nil {
            applyFirstCoordinates(nextLoc)
        } else {
            applyNewCoordinates(nextLoc)
        }
        
        self.txtLocation.text = nextLoc.location == nil ? self.txtLocation.text : nextLoc.location
    }
    
    func applyFirstCoordinates(_ nextLoc: VisLocation) {
        point = MGLPointAnnotation()
        point.coordinate = nextLoc.coordinate
        mapView.addAnnotation(point)
        
        camera.altitude = distance
        camera.pitch = 70
        camera.heading = 0.0
        camera.centerCoordinate = nextLoc.coordinate
        mapView.fly(to: camera, withDuration: 1.5, completionHandler: {
            UIView.animate(withDuration: 1) {
                self.imgPlane.alpha = 1
            }
        })
        
        txtStatus.text = "Sobrevoando agora"
    }
    
    func smoothRotation(_ lastBearing: Double, _ newBearing: Double) -> Double {
        return newBearing + 0.33 * (lastBearing - newBearing)
    }
    
    func applyNewCoordinates(_ nextLoc: VisLocation) {
        let l1 = CLLocation(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude)
        let l2 = CLLocation(latitude: nextLoc.coordinate.latitude, longitude: nextLoc.coordinate.longitude)
        
        let distance = l1.distance(from: l2).rounded()
        
        var rotation = camera.heading
        
        if(distance > 2.0) {
            rotation = bearing(point.coordinate, nextLoc.coordinate)
            rotation = (rotation * 100000).rounded() / 100000
            print(getDifference(camera.heading, rotation))
            camera.heading = rotation
        }
        
//        if distance < 10.0 {
//            rotation = 0.0
//            nextLoc.coordinate = point.coordinate
//        }
//        else if rotation > 35.0 {
//            rotation = 35.0
//        } else if rotation < -35.0 {
//            rotation = -35.0
//        }
        
        self.txtAltitude.text = String(format: "%.0fm", nextLoc.altitude)
        point.coordinate = nextLoc.coordinate
        
        camera.pitch = 70
        camera.centerCoordinate = nextLoc.coordinate
        
        mapView.setCamera(camera, withDuration: 1.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear), edgePadding: UIEdgeInsetsMake(280, 0, 118, 0))
        
        print("[vis] [dequeue] lat:\(nextLoc.coordinate.latitude),lon:\(nextLoc.coordinate.longitude),head:\(rotation),dist:\(distance)")
    }
    
    func getDifference(_ a1: Double, _ a2: Double) -> Double {
        return min((a1 - a2) < 0 ? (a1 - a2 + 360) : (a1 - a2), (a2-a1) < 0 ? (a2 - a1 + 360) : (a2 - a1))
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func bearing(_ startPoint: CLLocationCoordinate2D, _ endPoint: CLLocationCoordinate2D) -> Double {
        
        let lat1 = degreesToRadians(degrees: startPoint.latitude)
        let lon1 = degreesToRadians(degrees: startPoint.longitude)
        
        let lat2 = degreesToRadians(degrees: endPoint.latitude)
        let lon2 = degreesToRadians(degrees: endPoint.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    func startTimer() {
        print("[vis] start timer...")
        
        stopTimer()
        
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        guard self.timer != nil else {
            return
        }
        
        print("[vis] stop timer")
        
        self.timer.invalidate()
        
        self.timer = nil
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
    
    func setNavigationBar() {
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        let menuItem = UIBarButtonItem(image: UIImage(named: "IconMenu"), style: .plain,target: self, action: #selector(openMenu))
        navItem.leftBarButtonItem = menuItem
        let placeItem = UIBarButtonItem(image: UIImage(named: "IconZoom"), style: .plain,target: self, action: #selector(center))
        navItem.rightBarButtonItem = placeItem
        
        if let company = UserDefaults.standard.string(forKey: "company") {
            self.navBar.topItem?.title = company
        }
    }
    
    func setNavigationDrawer() {
        let options = NavigationDrawerOptions()
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
        userRef.observe(.value, with: { snapshot in
            if let child = snapshot.value as? [String:Any] {
                guard let campaignId = child["campaign"] as? String else {
                    return
                }
                
                self.dismissLargeAlert()
                self.btnDetail.isEnabled = true
                
                self.campaignRef = Database.database().reference(withPath: "campaign").child(campaignId)
                
                self.campaignRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let cDict = snapshot.value as? [String:Any] else {
                        return
                    }
                    
                    if self.campaign == nil {
                        self.txtStatus.text = "Status"
                        self.txtLocation.text = "Obtendo dados da campanha..."
                        
                        self.setCampaignData(campaignId, cDict)
                        
                        self.txtStatus.text = "Status"
                        self.txtLocation.text = "Aguardando decolagem..."
                    }
                    
                    self.campaignRef.child("active").observe(.value, with: { (snapshot) in
                        guard let active = snapshot.value as? Bool else {
                            return
                        }
                        
                        self.campaign.active = active
                        
                        if active {
//                            self.campaignRef.child("heading").observe(.value, with: { snapshot in
//                                guard let heading = snapshot.value as? Double else {
//                                    return
//                                }
//
//                                self.camera.heading = heading
//                                self.camera.pitch = 70
//
//                                self.mapView.setCamera(self.camera, withDuration: 1.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear), edgePadding: UIEdgeInsetsMake(280, 0, 28, 0))
//                            })
                            
                            self.campaignRef.child("location").observe(.value, with: { snapshot in
                                guard let locDict = snapshot.value as? [String:Any] else {
                                    return
                                }
                                
                                let newLat = locDict["latitude"] as! Double
                                let newLon = locDict["longitude"] as! Double
                                let newAlt = locDict["altitude"] as! Double
                                
                                let coordinate = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
                                let visLocation = VisLocation()
                                visLocation.coordinate = coordinate
                                visLocation.altitude = newAlt
                                
                                if let location = locDict["description"] as? String, !location.isEmpty {
                                    visLocation.location = location
                                }
                                
                                self.campaign.position = visLocation
                                
                                if self.posQueue == nil {
                                    self.posQueue = Queue<VisLocation>()
                                }
                                
                                print("[vis] [enqueue] lat:\(visLocation.coordinate.latitude),lon:\(visLocation.coordinate.longitude),loc:\(visLocation.location ?? "nil")")
                                self.posQueue.enqueue(visLocation)
                                
                                if self.timer == nil {
                                    self.startTimer()
                                }
                            })
                        } else {
                            self.campaignRef.child("location").removeAllObservers()
                        }
                    })
                })
            } else {
                if self.campaignRef != nil {
                    self.campaignRef.child("active").removeAllObservers()
                    self.campaignRef.child("location").removeAllObservers()
                    self.campaignRef.removeAllObservers()
                }
                
                self.presentLargeAlert(self, {})
                self.btnDetail.isEnabled = false
                
                self.campaign = nil
            }
        })
    }
    
    private func clear() {
        if self.campaign != nil {
            self.campaign.position = nil
        }
        
        self.posQueue = nil
        
        self.imgPlane.alpha = 0
        
        self.centerMap()
    }
    
    private func setCampaignData(_ campaignId: String, _ cDict: [String:Any]) {
        self.txtCampaign.text = (cDict["name"] as? String)?.uppercased()
        self.txtPrefix.text = (cDict["plane"] as? String)?.uppercased()
        self.txtPlace.text = (cDict["place"] as? String)?.uppercased()
        
        self.campaign = Campaign()
        self.campaign.id = campaignId
        self.campaign.name = cDict["name"] as? String
        self.campaign.plane = cDict["plane"] as? String
        self.campaign.place = Place()
        self.campaign.place.title = cDict["place"] as? String
        self.campaign.bandName = cDict["band"] as? String
        
        let storage = Storage.storage()
        let refBand = storage.reference().child("campaigns/\(campaignId)/\(campaign.bandName!)")
        
        refBand.getData(maxSize: 8 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
            } else {
                self.campaign.band = data!
            }
        }
        
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
    }
    
    @objc func center() {
        if self.campaign != nil && self.campaign.position != nil {
            if self.distance < 80000 {
                if self.distance > 40000 {
                    self.navItem.rightBarButtonItem?.image = UIImage(named: "IconPlace")
                }
                
                self.distance *= 2.1
            } else {
                self.navItem.rightBarButtonItem?.image = UIImage(named: "IconZoom")
                
                self.distance = 1000
            }
            
            camera.altitude = self.distance
            camera.pitch = 70
            
            if self.posQueue == nil || self.posQueue.isEmpty {
                mapView.setCamera(camera, withDuration: 1.8, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
            }
        } else {
            self.centerMap()
        }
    }
    
//    @objc func doubleTapMap() {
//
//    }
}

