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
    
    var campaign: Campaign!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtPlane.text = self.campaign.plane
        txtName.text = self.campaign.name.replacingOccurrences(of: "VERAO ", with: "", options: .literal, range: nil)
        txtPlace.text = self.campaign.place.title.uppercased()
        
        if self.campaign.band != nil {
            imgBand.image = UIImage(data: self.campaign.band)
        }
        
        if self.campaign.place.pic1 != nil {
            imgPic1.image = UIImage(data: self.campaign.place.pic1)
        }
        
        if self.campaign.place.pic2 != nil {
            imgPic2.image = UIImage(data: self.campaign.place.pic2)
        }
        
        if self.campaign.place.pic3 != nil {
            imgPic3.image = UIImage(data: self.campaign.place.pic3)
        }
    }
    
    //MARK: Properties
    
    //MARK: Actions
    @IBAction func back() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "SegueUnwindToMap", sender: self)
        }
    }
}
