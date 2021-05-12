//
//  Address.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/18/21.
//

import Foundation
import CoreLocation
import Firebase

struct Address {
    
    let state: String
    let street_address: String
    let city: String
    let latitude: Double
    let longitude: Double
    
    init(state: String, street_address: String, city: String, latitude: Double, longitude: Double) {
        self.state = state
        self.street_address = street_address
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init?(dictionary: [String:Any]) {
        guard let unwrappedState = dictionary["state"],
              let unwrappedStreetAddress = dictionary["street_address"],
              let unwrappedCity = dictionary["city"],
              let unwrappedLatitude = dictionary["latitude"],
              let unwrappedLongitude = dictionary["longitude"],
              let validState = unwrappedState as? String,
              let validStreetAddress = unwrappedStreetAddress as? String,
              let validCity = unwrappedCity as? String,
              let validLatitude = unwrappedLatitude as? Double,
              let validLongitude = unwrappedLongitude as? Double else {
            print("Invalid dictionary data: \(dictionary), cannot construct an Address.")
            return nil
        }
        self.state = validState
        self.street_address = validStreetAddress
        self.city = validCity
        self.latitude = validLatitude
        self.longitude = validLongitude
    }
    
    static func geocodeLatitudeAndLongitude(city: String, street: String, state: String, completion:@escaping((CLLocationCoordinate2D?) -> ())) {
        let geoCoder = CLGeocoder()

        var coordinates: CLLocationCoordinate2D?

        let address = "\(street), \(city), \(state)"

        let group = DispatchGroup()

        geoCoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
            coordinates = processResponse(withPlacemarks: placemarks, error: error)
            group.leave()
        })
        group.enter()

        group.notify(queue: .main) {
            completion(coordinates)
        }
    }
    
    func toAnyObject() -> Any {
        return [
            "state": self.state as NSObject,
            "street_address": self.street_address as NSObject,
            "city": self.city as NSObject,
            "latitude": self.latitude,
            "longitude": self.longitude
        ]
    }
    
    func toUserProfileDictionary() -> [String:Any] {
        return [
            "state": self.state,
            "street_address": self.street_address,
            "city": self.city,
            "latitude": self.latitude,
            "longitude": self.longitude
        ]
    }
}

private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) -> CLLocationCoordinate2D? {
    var coordinate: CLLocationCoordinate2D?
    if let error = error {
        print("Unabled to Forward Geocode Address \(error)")
        // TODO: Add a label or alert letting the user know that their address input is invalid.
    } else {
        var location: CLLocation?
        
        if let unwrappedPlacemarks = placemarks, unwrappedPlacemarks.count > 0 {
            location = unwrappedPlacemarks.first?.location
        }
        
        if let unwrappedLocation = location {
            coordinate = unwrappedLocation.coordinate
        } else {
            print("Could not find a coordinate for the given location: \(location)")
        }
    }
    return coordinate
    
}
