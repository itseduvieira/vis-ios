//
//  MGLPlaneAnnotationView.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 22/09/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit
import Mapbox

class PlaneAnnotationView: MGLAnnotationView {
    var imageView: UIImageView!
    weak var controller: MapController!
    
    required init(reuseIdentifier: String?, image: UIImage) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.imageView = UIImageView(image: image)
        self.addSubview(self.imageView)
        self.frame = self.imageView.frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if (event == "position" && controller != nil) {
            let position = CABasicAnimation(keyPath: event)
            position.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            position.duration = 5

            return position
        }

        return super.action(for: layer, forKey: event)
    }
    
    func rotate(radians: CGFloat) {
        UIView.animate(withDuration: 2, animations: {
            print(radians)
            self.transform = CGAffineTransform(rotationAngle: radians)
        })
    }
}
