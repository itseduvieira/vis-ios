//
//  DrawerController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 17/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit

class DrawerController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let menu = [ "Minhas Campanhas", "Sair" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        cell?.textLabel?.text = menu[indexPath.row]
        
        return cell!
    }
}
