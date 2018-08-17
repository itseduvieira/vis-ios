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
    
    var id: String!
    var name: String!
    var place: String!
    var plane: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtPlane.text = self.plane
        txtName.text = self.name.replacingOccurrences(of: "VERAO ", with: "", options: .literal, range: nil)
        txtPlace.text = self.place.uppercased()
    }
    
    //MARK: Properties
    
    //MARK: Actions
    @IBAction func back() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "SegueUnwindToMap", sender: self)
        }
    }
}
