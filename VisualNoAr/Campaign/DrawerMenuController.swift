//
//  DrawerMenuController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 17/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit
import FirebaseAuth

class DrawerMenuController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtName: UILabel!
    @IBOutlet weak var txtEmail: UILabel!
    
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
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell?.textLabel?.text = menu[indexPath.row]
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NavigationDrawer.sharedInstance.toggleNavigationDrawer { () -> Void in
            switch indexPath.row {
            case 0:
                
                print("case 0")
                
                break
            case 1:
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Error at signOut")
                }
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "SegueMenuToLogin", sender: self)
                }
                
                break
            default:
                
                print("default")
                
            }
        }
    }
}
