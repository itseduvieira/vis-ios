//
//  CLLocationCoordinate2DExtension.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 23/09/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import Mapbox

extension CLLocationCoordinate2D {
    
    func getRadiansFrom(degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180
    }
    
    func getDegreesFrom(radians: CGFloat) -> CGFloat {
        return radians * 180 / .pi
    }
    
    func bearingRadianTo(location: CLLocationCoordinate2D) -> CGFloat {
        let lat1 = self.getRadiansFrom(degrees: CGFloat(self.latitude))
        let lon1 = self.getRadiansFrom(degrees: CGFloat(self.longitude))
        
        let lat2 = self.getRadiansFrom(degrees: CGFloat(location.latitude))
        let lon2 = self.getRadiansFrom(degrees: CGFloat(location.longitude))
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var radiansBearing = atan2(y, x)
        
        if radiansBearing < 0.0 {
            radiansBearing += 2 * .pi
        }
        
        return CGFloat(radiansBearing)
    }
    
    func bearingDegreesTo(location: CLLocationCoordinate2D) -> CGFloat {
        return self.getDegreesFrom(radians: self.bearingRadianTo(location: location))
    }
}
