//
//  HomeViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/19/21.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    var user: User!
    
    var userProfile: UserProfile?
    
    var userProfileDatabaseReference: DatabaseReference?
    
    var conversationsDatabaseReference: DatabaseReference?
    
    var coderMatchingProfileReference: DatabaseReference?
    
    private let homeToNearbyCodersMap = "HomeToNearbyCodersMap"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var path: String?
        var conversationsPath: String?
        var coderMatchingPath: String?
        
        do {
            path = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
            conversationsPath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.Conversations])
            coderMatchingPath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.CoderMatchingProfile])
        } catch {
            print("WARNING, database path not found for user profile reference.")
        }
        
        guard let unwrappedPath = path, let unwrappedConversationsPath = conversationsPath, let unwrappedCoderMatchingPath = coderMatchingPath else {
            return
        }
        
        self.userProfileDatabaseReference = Database.database().reference(withPath: unwrappedPath)
        
        self.conversationsDatabaseReference = Database.database().reference(withPath: unwrappedConversationsPath)
        
        self.coderMatchingProfileReference = Database.database().reference(withPath: unwrappedCoderMatchingPath)
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let unwrappedUser = user else {
                print("No user available in home screen, backing out now.")
                return
            }
            self.user = User(authData: unwrappedUser)
            
            guard let unwrappedUserProfileDatabaseReference = self.userProfileDatabaseReference else {
                print("User database reference not initialized, backing out of add state change listener, user profile will not be set.")
                return
            }
            
            unwrappedUserProfileDatabaseReference.child(self.user.uid).observeSingleEvent(of: .value, with: { snapshot in
                self.userProfile = UserProfile(snapshot: snapshot)
                guard let unwrappedUserProfileDetails = self.userProfile else {
                    print("User profile entity not fetched from snapshot. Can't update UI.")
                    return
                }
                self.lblUserProfileDetails.text = "Hello \(unwrappedUserProfileDetails.firstName)"
                UserDefaults.standard.set(unwrappedUserProfileDetails.toUserDefaultsDictionary(), forKey: unwrappedPath)
            })
        }
        
    }
    
    @IBAction func btnViewCoders(_ sender: UIButton) {
        guard let unwrappedUserProfile = self.userProfile,
              let unwrappedCoderMatchingProfileRef = self.coderMatchingProfileReference else {
            print("The user profile for this view controller or the coder matching firebase reference is nil, can't transition to the view coders screen.")
            return
        }
        
        unwrappedCoderMatchingProfileRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.hasChild(unwrappedUserProfile.uid) {
                self.performSegue(withIdentifier: self.homeToNearbyCodersMap, sender: nil)
            } else {
                let buttonPressAlert = UIAlertController(title: "Edit Profile first!", message: "You need to add a coding profile first before viewing nearby coders.", preferredStyle: .alert)
                buttonPressAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(buttonPressAlert, animated: true, completion: nil)
            }
        })
    }
    
    @IBOutlet weak var lblUserProfileDetails: UILabel!
    
    @IBAction func btnLogoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: DatabaseCollections[Collections.UserProfile]!)
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            print("Auth sign out failed: \(error)")
        }
    }
    
}
