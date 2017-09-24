//
//  UIViewExtensions.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 18/08/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fadeIn(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
    
    func setRadius(radius: CGFloat? = nil) {
        self.layer.cornerRadius = radius ?? self.frame.width / 2;
        self.layer.masksToBounds = true;
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIImage {
    public func rotate(degrees: CGFloat, flip: Bool, completion: @escaping (UIImage) -> Void) {
        
        DispatchQueue.main.async {
            
            
            //        let radiansToDegrees: (CGFloat) -> CGFloat = {
            //            return $0 * (180.0 / CGFloat(Double.pi))
            //        }
            
            let degreesToRadians: (CGFloat) -> CGFloat = {
                return $0 / 180.0 * CGFloat(Double.pi)
            }
            
            // calculate the size of the rotated view's containing box for our drawing space
            let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: self.size))
            let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
            rotatedViewBox.transform = t
            let rotatedSize = rotatedViewBox.frame.size
            
            // Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap = UIGraphicsGetCurrentContext()
            
            // Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap!.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
            
            //   // Rotate the image context
            bitmap!.rotate(by: degreesToRadians(degrees));
            
            // Now, draw the rotated/scaled image into the context
            var yFlip: CGFloat
            
            if(flip){
                yFlip = CGFloat(-1.0)
            } else {
                yFlip = CGFloat(1.0)
            }
            
            bitmap!.scaleBy(x: yFlip, y: -1.0)
            bitmap!.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            completion(newImage!)
        }
    }
}
