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
    
    let navigationDrawer = NavigationDrawer.sharedInstance
    
    var campaign: Campaign!
    var timer: Timer!
    var camera: MGLMapCamera!
    var posQueue: Queue<VisLocation>!
    var lastPosition: CLLocationCoordinate2D!
    var distance: CLLocationDistance = 90 * 1000
    
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
        
        self.userRef.removeAllObservers()
        if self.campaignRef != nil {
            self.campaignRef.removeAllObservers()
            self.campaignRef.child("active").removeAllObservers()
            self.campaignRef.child("location").removeAllObservers()
        }
    }
    
    @objc func runTimedCode() {
        guard let nextLoc = self.posQueue.dequeue() else {
            if campaign == nil {
                self.presentLargeAlert(self, {
                    self.clear()
                })
            } else if !campaign.active {
                let alert = UIAlertController(title: "Campanha Encerrada", message: "Sua campanha acabou de ser exibida com sucesso!", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.clear()
                }))
                
                self.present(alert, animated: true)
            }
            
            self.stopTimer()
            
            return
        }
        
        var rotation = 0.0
        mapView.setContentInset(UIEdgeInsetsMake(156, 0, 28, 0), animated: false)
        self.txtAltitude.text = String(format: "%.0fm", nextLoc.altitude)
        self.txtLocation.text = nextLoc.location
        
        if point == nil {
            point = MGLPointAnnotation()
            mapView.addAnnotation(point)
        }
        
        point.coordinate = nextLoc.coordinate
        
        if let lastPosition = self.lastPosition {
            rotation = Double(lastPosition.bearingDegreesTo(location: nextLoc.coordinate))
            camera.centerCoordinate = nextLoc.coordinate
            camera.heading = rotation
            mapView.setCamera(camera, withDuration: 2.5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
        } else {
            self.camera.altitude = self.distance
            self.camera.centerCoordinate = nextLoc.coordinate
            self.mapView.fly(to: self.camera, withDuration: 2.5, completionHandler: { })
            UIView.animate(withDuration: 1) {
                self.imgPlane.alpha = 1
            }
        }
        
        print("[ticking] lat:\(nextLoc.coordinate.latitude),lon:\(nextLoc.coordinate.longitude),rot:\(rotation)")
        
        lastPosition = nextLoc.coordinate
    }
    
    func startTimer() {
        print("start timer...")
        
        stopTimer()
        
        timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        guard self.timer != nil else {
            return
        }
        
        print("stop timer")
        
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
    
    func mapView(_ mapView: MGLMapView, regionDidChangeWith reason: MGLCameraChangeReason, animated: Bool) {
        print("regionDidChangeWith")
        
        if reason == .programmatic {
            mapView.setContentInset(UIEdgeInsetsMake(156, 0, 28, 0), animated: false)
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        self.mapView = mapView
        
        setMapConfig()
    }
    
    func setMapConfig() {
        self.mapView.isUserInteractionEnabled = false
        
        self.centerMap()
        
        topInfoContainer.setRadius(radius: 3)
        imgStatus.backgroundColor = UIColor(hexString: "#00E08A")
        imgStatus.setRadius(radius: 5.5)
    }
    
    func centerMap() {
        let coordinate = CLLocationCoordinate2D(latitude: -20.0, longitude: -47.8825)
        camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: 13000 * 1000, pitch: 0, heading: 0)
        
        self.mapView.fly(to: camera, withDuration: 2.5, completionHandler: {})
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
        userRef.observe(DataEventType.value, with: { (snapshot) in
            if let child = snapshot.value as? [String:Any] {
                guard let campaignId = child["campaign"] as? String else {
                    return
                }
                
                self.dismissLargeAlert()
                
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
                
                self.campaignRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let cDict = snapshot.value as? [String:Any] else {
                        return
                    }
                    
                    if self.campaign == nil {
                        self.setCampaignData(campaignId, cDict)
                    }
                    
                    self.campaignRef.child("active").observe(.value, with: { (snapshot) in
                        guard let active = snapshot.value as? Bool else {
                            return
                        }
                        
                        self.campaign.active = active
                        
                        if active {
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
                                
                                if let location = locDict["description"] as? String {
                                    visLocation.location = location
                                }
                                
                                self.campaign.position = visLocation
                                
                                if self.posQueue == nil {
                                    self.posQueue = Queue<VisLocation>()
                                }
                                
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
                self.campaignRef.child("active").removeAllObservers()
                self.campaignRef.child("location").removeAllObservers()
                self.campaignRef.removeAllObservers()
                
                self.campaign = nil
            }
        })
    }
    
    private func clear() {        
        if self.campaign != nil {
            self.campaign.position = nil
        }
        
        self.lastPosition = nil
        
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
            if self.distance < 720000 {
                self.distance *= 2
            } else {
                self.distance = 90 * 1000
            }
            
            camera.altitude = self.distance
        } else {
            self.centerMap()
        }
    }
    
    
}

