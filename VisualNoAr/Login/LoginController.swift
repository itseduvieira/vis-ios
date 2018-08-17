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
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var controls: UIView!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        txtEmail.applyBottomBorder(UIColor.white)
        txtPassword.applyBottomBorder(UIColor.white)
        
        btnLogin.setRadius(radius: 22)
        
        self.checkAndFillSavedCredentials()
        
        UIView.animate(withDuration: 1.5, animations: {
            self.background.alpha = 0.4
        })
    }
    
    @IBAction func showOrHidePass(_ sender: UIButton) {
        txtPassword.isSecureTextEntry = !txtPassword.isSecureTextEntry
        if txtPassword.isSecureTextEntry {
            sender.setImage(UIImage(named: "RevealPasswordIcon"), for: .normal)
        } else {
            sender.setImage(UIImage(named: "HidePasswordIcon"), for: .normal)
        }
    }
    
    @IBAction func login() {
        self.presentAlert()
        
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

