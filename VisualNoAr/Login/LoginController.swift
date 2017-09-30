//
//  LoginController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 03/05/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit

class LoginController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginContainer.setRadius(radius: 3)
        
        btnLogin.setRadius(radius: 22)
    }
}

