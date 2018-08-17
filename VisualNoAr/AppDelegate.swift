//
//  AppDelegate.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 03/05/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import KYDrawerController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var drawerController = KYDrawerController.init(drawerDirection: .left, drawerWidth: 300)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Fabric.sharedSDK().debug = true
        
        let storyboard = UIStoryboard.init(name: "Campaign", bundle: Bundle.main)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "MapViewController")
        let menuVC = storyboard.instantiateViewController(withIdentifier: "DrawerViewController")
        
        self.drawerController.mainViewController = mainVC
        self.drawerController.drawerViewController = menuVC
        
        self.window?.rootViewController = self.drawerController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}

