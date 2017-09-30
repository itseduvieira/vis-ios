//
//  LoginController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 03/05/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    //MARK: Properties
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        loginContainer.setRadius(radius: 3)
        
        btnLogin.setRadius(radius: 22)
        
        self.checkAndFillSavedCredentials()
    }
    
    @IBAction func login() {
        if let email = txtEmail.text, let password = txtPassword.text {
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        
                        return
                    }
                
                UserDefaults.standard.set(email, forKey: "username")
                UserDefaults.standard.set(password, forKey: "password")
                
                self.goToNextScene()
            }
        } else {
            print("email/password can't be empty")
        }
    }
    
    private func checkAndFillSavedCredentials() {
        if let email = UserDefaults.standard.string(forKey: "username"),
                let password = UserDefaults.standard.string(forKey: "password") {
            txtEmail.text = email
            txtPassword.text = password
        }
    }
    
    private func goToNextScene() {
        var controllerId = "TutorialViewController"
        var sb = self.storyboard
        
        if UserDefaults.standard.bool(forKey: "tutorial") {
            controllerId = "MapViewController"
            sb = UIStoryboard(name: "Campaign", bundle:nil)
        }
        
        let next = sb?.instantiateViewController(withIdentifier: controllerId)
        self.present(next!, animated: true, completion: nil)
    }
}

