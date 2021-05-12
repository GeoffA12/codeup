//
//  CoderMapViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/22/21.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

class CoderMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var activeUser: UserProfile?
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var database: DatabaseReference?
    
    var nearbyMatchingUsers: [UserProfile]?
    
    let matchingUserLocationRadius = 0.07
    
    private let radiusRegion: CLLocationDistance = 2000

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapNearbyCoders.delegate = self
        
        var userProfilePath: String?
        
        do {
            userProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
        } catch (let error) {
            print(error)
        }
        
        guard let unwrappedUserProfilePath = userProfilePath else {
            print("User profile database path not found, backing out of viewDidLoad() now")
            return
        }
        
        guard let unwrappedUserProfile = UserDefaults.standard.object(forKey: unwrappedUserProfilePath),
              let validUserProfileDictionary = unwrappedUserProfile as? [String:Any],
              let validUserProfile = UserProfile(dictionary: validUserProfileDictionary) else {
            print("Couldn't construct a valid user profile based on user defaults user profile key. Backing out of viewDidLoad()")
            return
        }
        
        self.database = Database.database().reference(withPath: unwrappedUserProfilePath)
        
        self.activeUser = validUserProfile
        
        guard let unwrappedDatabaseReference = self.database,
              let unwrappedActiveUser = self.activeUser else {
            print("Couldn't establish a connection to a Firebase reference for the user profile collection, backing out of viewDidLoad()")
            return
        }
        
        let activeUserLatitude = unwrappedActiveUser.address.latitude
        let activeUserLongitude = unwrappedActiveUser.address.longitude
        
        let minLatitude = activeUserLatitude - self.matchingUserLocationRadius
        let maxLatitude = activeUserLatitude + self.matchingUserLocationRadius
        
        let minLongitude = activeUserLongitude - self.matchingUserLocationRadius
        let maxLongitude = activeUserLongitude + self.matchingUserLocationRadius
        
        // TODO: Find out how to use queries to get all of the user profile records with a latitude within min and max lat, and lon.
        
        let addressRef = unwrappedDatabaseReference.queryOrdered(byChild: "address")
        
        self.nearbyMatchingUsers = []
        
        addressRef.observe(.value, with: { snapshot in
            for child in snapshot.children {
                guard let userProfileSnapshot = child as? DataSnapshot,
                      let userProfile = UserProfile(snapshot: userProfileSnapshot) else {
                    print("Couldn't construct a user profile based on snapshot data: \(child)")
                    return
                }
                // TODO: Integrate percent match function which will compare the matching profiles of each user here
                if userProfile.uid != unwrappedActiveUser.uid {
                    if userProfile.address.latitude >= minLatitude && userProfile.address.latitude <= maxLatitude {
                        if userProfile.address.longitude >= minLongitude &&  userProfile.address.longitude <= maxLongitude {
                            self.nearbyMatchingUsers?.append(userProfile)
                        }
                    }
                }
            }
            self.mapSetup()
        })
    }
    
    @IBOutlet weak var mapNearbyCoders: MKMapView!
    
    func mapSetup() {
        var annotations: [Annotation] = []
        
        guard let unwrappedActiveUser = self.activeUser,
              let unwrappedNearbyUsers = self.nearbyMatchingUsers else {
            print("Can't set annotations as the active user or nearby users is set to nil.")
            return
        }
        
        let activeUserAnnotation = Annotation(user: unwrappedActiveUser, lat:unwrappedActiveUser.address.latitude, lon: unwrappedActiveUser.address.longitude, title: "You", subtitle: "You are here!", type: LocationType.activeUser)
        
        annotations.append(activeUserAnnotation)
        
        for user in unwrappedNearbyUsers {
            let nearbyUserAnnotation = Annotation(user: user, lat: user.address.latitude, lon: user.address.longitude, title: user.firstName + " " + user.lastName, subtitle: "Nearby Coder", type: LocationType.nearybyUser)
            annotations.append(nearbyUserAnnotation)
        }
        
        let region = MKCoordinateRegion(center: activeUserAnnotation.coordinate, latitudinalMeters: self.radiusRegion, longitudinalMeters: self.radiusRegion)
        
        mapNearbyCoders.setRegion(region, animated: true)
        
        mapNearbyCoders.addAnnotations(annotations)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = MKMarkerAnnotationView()
        
        guard let annotation = annotation as? Annotation else {
            return nil
        }
        
        let defaultColor = UIColor.black
        var color = defaultColor
        var identifier = ""
        switch annotation.type {
            case .activeUser:
                color = UIColor.yellow
                identifier = "You"
            case .nearybyUser:
                color = UIColor.blue
                identifier = "Nearby Coder"
        }
        if let dequedView = mapNearbyCoders.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            annotationView = dequedView
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        annotationView.markerTintColor = color
        annotationView.clusteringIdentifier = identifier
        annotationView.displayPriority = .required
        annotationView.canShowCallout = true
        
        let btn = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = btn
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? Annotation else {
            print("Unknown type tapped on accessory")
            return
        }
        // TODO: Find a better way to do this filter
        if (annotation.title != "You") {
            self.performSegue(withIdentifier: "MapToDetails", sender: annotation)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let unwrappedAnnotation = sender as? Annotation else {
            print("Sender was not a valid annotation in prepare for segue function, will not transition properly to the coder details view controller.")
            return
        }
        if let vc = segue.destination as? CoderDetailsViewController {
            vc.matchedCoderUserProfile = unwrappedAnnotation.user
        }
    }
}
