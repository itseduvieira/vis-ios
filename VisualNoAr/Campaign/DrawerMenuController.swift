//
//  DrawerMenuController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 17/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit

class DrawerMenuController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtName: UILabel!
    @IBOutlet weak var txtEmail: UILabel!
    
    let icon = [ "IconPlane", "IconExit" ]
    let menu = [ "Minhas Campanhas", "Sair" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let name = UserDefaults.standard.string(forKey: "name") {
            txtName.text = name
        }
        
        if let email = UserDefaults.standard.string(forKey: "username") {
            txtEmail.text = email
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        if let label = cell?.viewWithTag(10) as? UILabel {
            label.text = menu[indexPath.row]
        }
        
        if let img = cell?.viewWithTag(20) as? UIImageView {
            img.image = UIImage(named: icon[indexPath.row])
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            if let map = NavigationDrawer.sharedInstance.delegate as? MapController {
                map.goToHistory()
            }
            
            break
        case 1:
            if let map = NavigationDrawer.sharedInstance.delegate as? MapController {
                map.logout()
            }
            
            break
        default:
            
            print("default")
            
        }
    }
}
