//
//  LoginController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 03/05/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Firebase
import PromiseKit

class LoginController: UIViewController {
    //MARK: Properties
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var controls: UIView!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        txtEmail.applyBottomBorder(UIColor.white)
        txtPassword.applyBottomBorder(UIColor.white)
        
        btnLogin.setRadius(radius: 22)
        
        UIView.animate(withDuration: 1.5, animations: {
            self.background.alpha = 0.4
        })
        
        self.checkAndFillSavedCredentials()
        
        self.setNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Auth.auth().currentUser == nil {
            view.backgroundColor = UIColor.black
            for v in view.subviews {
                v.isHidden = false
            }
        } else {
            self.goToNextScene()
        }
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
        if let email = txtEmail.text, let password = txtPassword.text {
            self.presentAlert()
            
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if let error = error {
                        self.dismissCustomAlert()
                        
                        var errorMsg = "Erro ao realizar login."
                        
                        let errCode = AuthErrorCode(rawValue: error._code)!
                        
                        switch errCode {
                        case .userNotFound, .wrongPassword:
                            errorMsg = "Usuário ou senha inválidos."
                            break
                        default:
                            print(error)
                        }
                        
                        let alertController = UIAlertController(title: "Erro", message: errorMsg, preferredStyle: .alert)
                        
                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(defaultAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                        
                        return
                    }
                
                UserDefaults.standard.set(email, forKey: "username")
                UserDefaults.standard.set(password, forKey: "password")
                
                self.getUserAndGoToNextScene()
            }
        } else {
            let alertController = UIAlertController(title: "Erro", message: "Preencha os campos de email e senha.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
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
        if UserDefaults.standard.bool(forKey: "tutorial") {
            self.performSegue(withIdentifier: "SegueLoginToMap", sender: self)
        } else {
            self.performSegue(withIdentifier: "SegueLoginToTutorial", sender: self)
        }
    }
    
    private func getUserAndGoToNextScene() {
        firstly {
            DataAccess.instance.getUser()
        }.done {
            self.goToNextScene()
        }.catch { error in
            print(error)
            
            self.goToNextScene()
        }
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueLoginToForgot" {
            let destination = segue.destination as! ForgotController
            if let email = txtEmail.text {
                destination.email = email
            }
        }
    }
    
    @IBAction func goToForgot() {
        self.performSegue(withIdentifier: "SegueLoginToForgot", sender: self)
    }
}

