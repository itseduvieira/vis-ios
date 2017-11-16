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
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.fromValue = controller.actualRadian
            rotation.toValue = controller.actualRadian
            rotation.duration = 5
            
            let position = CABasicAnimation(keyPath: event)
            position.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            position.duration = 4
            
            //controller.mapView.setCenter(<#T##coordinate: CLLocationCoordinate2D##CLLocationCoordinate2D#>, animated: <#T##Bool#>)
            
            let animation = CAAnimationGroup()
            animation.animations = [rotation, position]
            animation.duration = 5
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            
            return animation
        }
        
        return super.action(for: layer, forKey: event)
    }
}
