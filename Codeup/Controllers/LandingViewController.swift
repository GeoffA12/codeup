//
//  ViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/15/21.
//

import UIKit
import FirebaseDatabase
import Firebase

class LandingViewController: UIViewController {
    
    private var database: DatabaseReference?
    var dbUtils: DatabasePathUtils?

    override func viewDidLoad() {
        super.viewDidLoad()
        var path : String?
        
        do {
            try path = DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
        } catch {
            print("WARNING, database path not found!")
        }
        
        guard let validPath = path else {
            return
        }
        
        database = Database.database().reference(withPath: validPath)
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                self.lblEmailOutlet.text = nil
                self.lblPasswordOutlet.text = nil
                self.performSegue(withIdentifier: "LoginToHome", sender: nil)
            }
        }
        
    }
    
    @IBOutlet weak var lblEmailOutlet: UITextField!
    
    @IBOutlet weak var lblPasswordOutlet: UITextField!
    
    @IBAction func btnLoginTapped(_ sender: UIButton) {
        guard let unwrappedEmail = lblEmailOutlet.text, let unwrappedPassword = lblPasswordOutlet.text, unwrappedEmail.count > 0, unwrappedPassword.count > 0 else {
            print("Login data is invalid.")
            return
        }
        
        Auth.auth().signIn(withEmail: unwrappedEmail, password: unwrappedPassword) { user, error in
            if let error = error, user == nil {
                let loginFailedAlert = UIAlertController(title: "Login failed.", message: error.localizedDescription, preferredStyle: .alert)
                loginFailedAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(loginFailedAlert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnRegisterTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Register", message: "Register a new account", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            let firstNameField = alert.textFields![2]
            let lastNameField = alert.textFields![3]
            let ageField = alert.textFields![4]
            let stateField = alert.textFields![5]
            let cityField = alert.textFields![6]
            let streetAddressField = alert.textFields![7]
            
            guard let unwrappedEmail = emailField.text,
                  let unwrappedPassword = passwordField.text,
                  let unwrappedFirstName = firstNameField.text,
                  let unwrappedLastName = lastNameField.text,
                  let unwrappedAge = ageField.text,
                  let integerUnwrappedAge = Int(unwrappedAge) else {
                print("There were fields in the registration that were nil. Can't register new account.")
                return
            }
            
            guard let validState = stateField.text,
                  let validStreet = streetAddressField.text,
                  let validCity = cityField.text else {
                print("The country, city, and street name can't be nil.")
                return
            }
            var address: Address?
            var latitude: Double?
            var longitude: Double?
            
            let group = DispatchGroup()
            
            group.enter()
            
            Address.geocodeLatitudeAndLongitude(city: validCity, street: validStreet, state: validState, completion: { coordinate in
                guard let unwrappedCoordinatePair = coordinate else {
                    return
                }

                latitude = unwrappedCoordinatePair.latitude
                longitude = unwrappedCoordinatePair.longitude
                group.leave()
            })
            
            group.notify(queue: .main) {
                guard let unwrappedLatitude = latitude,
                      let unwrappedLongitude = longitude else {
                    print("Issue converting the address country, city, and street input into a geocoded lat and lon.")
                    return
                }
                
                address = Address(state: validState, street_address: validStreet, city: validCity, latitude: unwrappedLatitude, longitude: unwrappedLongitude)
                
                guard let unwrappedAddress = address,
                      let databaseReference = self.database else {
                    print("There was an issue with unwrapping the address given from the CL geocoder, or database reference hasn't been instantiated with a valid path.")
                    return
                }
        

                Auth.auth().createUser(withEmail: unwrappedEmail, password: unwrappedPassword) { user, error in
                    if error == nil && user != nil {
                        Auth.auth().signIn(withEmail: unwrappedEmail, password: unwrappedPassword)
                        
                        let userProfile = UserProfile(uid: user!.user.uid, firstName: unwrappedFirstName, lastName: unwrappedLastName, email: unwrappedEmail, age: integerUnwrappedAge, address: unwrappedAddress)
                        
                        databaseReference.child(userProfile.uid).setValue(userProfile.toAnyObject())
                       
                    }
                }
                
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField { textEmail in
          textEmail.placeholder = "Enter your email"
        }
        
        alert.addTextField { textPassword in
          textPassword.isSecureTextEntry = true
          textPassword.placeholder = "Enter your password"
        }
        
        alert.addTextField { textFirstName in
            textFirstName.placeholder = "Enter your first name"
        }
        
        alert.addTextField { textLastName in
            textLastName.placeholder = "Enter your last name"
        }
        
        alert.addTextField { textAge in
            textAge.placeholder = "Enter your age"
        }
        
        alert.addTextField { textCountry in
            textCountry.placeholder = "Enter your state"
        }
        
        alert.addTextField { textCity in
            textCity.placeholder = "Enter your city"
        }
        
        alert.addTextField { textStreet in
            textStreet.placeholder = "Enter your street address"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
}

