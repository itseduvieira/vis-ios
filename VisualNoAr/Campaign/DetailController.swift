//
//  DetailController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 04/09/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit

class DetailController: UIViewController {
    @IBOutlet weak var txtPlane: UILabel!
    @IBOutlet weak var txtName: UILabel!
    @IBOutlet weak var txtPlace: UILabel!
    @IBOutlet weak var txtCompany: UILabel!
    @IBOutlet weak var imgBand: UIImageView!
    @IBOutlet weak var imgPic1: UIImageView!
    @IBOutlet weak var imgPic2: UIImageView!
    @IBOutlet weak var imgPic3: UIImageView!
    @IBOutlet weak var txtPic1: UILabel!
    @IBOutlet weak var txtPic2: UILabel!
    @IBOutlet weak var txtPic3: UILabel!
    
    var campaign: Campaign!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtPlane.text = self.campaign.plane
        txtName.text = self.campaign.name.replacingOccurrences(of: "VERAO ", with: "", options: .literal, range: nil)
        txtPlace.text = self.campaign.place.title.uppercased()
        if let company = UserDefaults.standard.string(forKey: "company") {
            txtCompany.text = company.uppercased()
        }
        
        if self.campaign.band != nil {
            imgBand.image = UIImage(data: self.campaign.band)
        }
        
        if self.campaign.place.pic1 != nil {
            imgPic1.image = UIImage(data: self.campaign.place.pic1)
            txtPic1.text = self.campaign.place.urls[0]["file"]?.uppercased()
        }
        
        if self.campaign.place.pic2 != nil {
            imgPic2.image = UIImage(data: self.campaign.place.pic2)
            txtPic2.text = self.campaign.place.urls[1]["file"]?.uppercased()
        }
        
        if self.campaign.place.pic3 != nil {
            imgPic3.image = UIImage(data: self.campaign.place.pic3)
            txtPic3.text = self.campaign.place.urls[2]["file"]?.uppercased()
        }
    }
    
    func setNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
}
