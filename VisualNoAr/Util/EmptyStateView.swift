//
//  EmptyStateView.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 19/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import UIKit

class EmptyStateView: UIView {
    @IBOutlet weak var container: UIView!
    
    weak var parent: MapController!
    var dismiss: (() -> Swift.Void)!
    
    @IBAction func close(_ sender: Any) {
        self.parent.dismissLargeAlert()
        dismiss()
    }
    
    @IBAction func openMenu() {
        //self.parent.dismissLargeAlert()
        //dismiss()
        self.parent.openMenu()
    }
}
