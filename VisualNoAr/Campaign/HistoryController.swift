//
//  HistoryController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 02/09/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit
import PromiseKit

class HistoryController: UIViewController,  UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var table: UITableView!
    
    var campaigns: [Campaign]! = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = "Campanhas"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.view.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.dataSource = self
        table.delegate = self
        
        self.getData()
    }
    
    func getData() {
        firstly {
            DataAccess.instance.listCampaigns()
        }.done { campaigns in
            self.campaigns = campaigns
            
            self.table.reloadData()
        }.catch { error in
            print(error)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.campaigns.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CampaignCell", for: indexPath) as! CampaignCustomCell
        
        let campaign = self.campaigns[indexPath.row]
        
        cell.name.text = campaign.name
        cell.plane.text = campaign.plane
        cell.place.text = campaign.place.title
        cell.featuredLocations.text = "\(campaign.place.urls[0]["file"]!) • \(campaign.place.urls[1]["file"]!) • \(campaign.place.urls[2]["file"]!)"
        
        cell.circle.setRadius()
        
        return cell
    }
}

class CampaignCustomCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var circle: UIView!
    @IBOutlet weak var place: UILabel!
    @IBOutlet weak var featuredLocations: UILabel!
    @IBOutlet weak var plane: UILabel!
    
}
