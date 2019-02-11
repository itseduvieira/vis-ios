//
//  ForgotController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 02/09/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit
import PromiseKit

class ForgotController: UIViewController {
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var btnForgot: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    
    var email: String!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        txtEmail.applyBottomBorder(UIColor.white)
        
        if let email = self.email {
            txtEmail.text = email
        }
        
        btnForgot.setRadius(radius: 22)
        
        self.background.alpha = 0.4

        self.setNavigationBar()
    }

    func setNavigationBar() {        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    @objc func back() {
        self.performSegue(withIdentifier: "UnwindForgotToLogin", sender: self)
    }
    
    @IBAction func sendEmail() {
        guard let email = txtEmail.text else {
            let alert = UIAlertController(title: "Erro", message: "Preencha corretamente o email", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        guard email.contains(".") && email.contains("@") else {
            let alert = UIAlertController(title: "Erro", message: "O email não está em um formato válido", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        self.presentAlert()
        
        firstly {
            DataAccess.instance.sendForgotPassword(email)
        }.ensure {
            let alert = UIAlertController(title: "Sucesso", message: "Verifique sua caixa de email e siga as instruções para troca de senha", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                //self.performSegue(withIdentifier: "UnwindForgotToLogin", sender: self)
            }))
            
            self.dismissCustomAlert()
            
            self.present(alert, animated: true, completion: nil)
        }.catch { err in
            print(err)
        }
    }
}
