//
//  CLLocationCoordinate2DExtension.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 23/09/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import Mapbox

extension CLLocationCoordinate2D {
    
    func getRadiansFrom(degrees: Double) -> Double {
        
        return degrees * .pi / 180
        
    }
    
    func getDegreesFrom(radians: Double) -> Double {
        
        return radians * 180 / .pi
        
    }
    
    
    func bearingRadianTo(location: CLLocationCoordinate2D) -> Double {
        
        let lat1 = self.getRadiansFrom(degrees: self.latitude)
        let lon1 = self.getRadiansFrom(degrees: self.longitude)
        
        let lat2 = self.getRadiansFrom(degrees: location.latitude)
        let lon2 = self.getRadiansFrom(degrees: location.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var radiansBearing = atan2(y, x)
        
        if radiansBearing < 0.0 {
            
            radiansBearing += 2 * .pi
            
        }
        
        
        return radiansBearing
    }
    
    func bearingDegreesTo(location: CLLocationCoordinate2D) -> Double {
        
        return self.getDegreesFrom(radians: self.bearingRadianTo(location: location))
        
    }
    
    
}
