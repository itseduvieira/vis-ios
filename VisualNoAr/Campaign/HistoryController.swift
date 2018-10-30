//
//  HistoryController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 02/09/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit

class HistoryController: UIViewController {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationBar()
    }
    
    func setNavigationBar() {
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        
        let backItem = UIBarButtonItem(title: "Voltar", style: .plain, target: self, action: #selector(back))
        navItem.leftBarButtonItem = backItem
    }
    
    @objc func back() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as! MapController
        self.present(vc, animated: true, completion: {})
    }
}
