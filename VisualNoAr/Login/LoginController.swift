//
//  LoginController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 03/05/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialTextFields

class LoginController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtEmail: MDCTextField!
    @IBOutlet weak var txtPassword: MDCTextField!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginContainer.setRadius(radius: 3)
        
        btnLogin.setRadius(radius: 22)
        
        txtEmail.delegate = self
        txtEmail.delegate = self
        
        let txtEmailController = MDCTextInputControllerDefault(textInput: txtEmail)
        txtEmailController.activeColor = UIColor(hexString: "#00BAE1")
        txtEmailController.isFloatingEnabled = true
    }
}

