//
//  FirstPaController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 18/09/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit

class PageController: UIViewController {
    //MARK: Properties
    @IBOutlet weak var btnFirstToSecond: UIButton!
    @IBOutlet weak var btnSecondToThird: UIButton!
    @IBOutlet weak var btnThirdToStart: UIButton!
    
    weak var parentVC: TutorialController!
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnFirstToSecond?.setRadius(radius: 22)
        btnSecondToThird?.setRadius(radius: 22)
        btnThirdToStart?.setRadius(radius: 22)
    }
    
    @IBAction func showNextPage(_ sender: Any) {
        parentVC?.nextPage()
    }
    
    @IBAction func goToCampaign() {
        UserDefaults.standard.set(true, forKey: "tutorial")
        
        let sb = UIStoryboard(name: "Campaign", bundle:nil)
        let next = sb.instantiateViewController(withIdentifier: "MapViewController")
        self.present(next, animated: true, completion: nil)
    }
    
}
