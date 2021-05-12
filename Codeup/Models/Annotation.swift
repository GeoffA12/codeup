//
//  Annotation.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/22/21.
//

import Foundation
import MapKit
import CoreLocation

enum LocationType {
    case activeUser
    case nearybyUser
}

class Annotation: NSObject, MKAnnotation {
    // var uid: String?
    var user: UserProfile
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var title: String?
    var subtitle: String?
    var type: LocationType
    
    init(user: UserProfile, lat: CLLocationDegrees, lon: CLLocationDegrees, title: String, subtitle: String, type: LocationType) {
        self.user = user
        self.coordinate = CLLocationCoordinate2DMake(lat, lon)
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}
