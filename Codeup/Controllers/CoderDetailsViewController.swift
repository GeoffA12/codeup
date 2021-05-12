//
//  CoderDetailsViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/23/21.
//

import UIKit
import Firebase

class CoderDetailsViewController: UIViewController {
    
    var matchedCoderUserProfile: UserProfile?
    
    var activeUser: UserProfile?
    
    var coderProfileRef: DatabaseReference?
    
    var userProfileRef: DatabaseReference?
    
    var conversationsRef: DatabaseReference?
    
    var activeUserCodingProfile: CoderMatchingProfile?
    
    var matchedUserCodingProfile: CoderMatchingProfile?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var userProfilePath : String?
        var coderProfilePath : String?
        var conversationsPath: String?
        
        do {
            userProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
            coderProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.CoderMatchingProfile])
            conversationsPath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.Conversations])
        } catch (let error) {
            print(error)
        }
        
        guard let unwrappedCoderProfilePath = coderProfilePath,
              let unwrappedUserProfilePath = userProfilePath,
              let unwrappedConversationsPath = conversationsPath,
              let userDefaultsUserProfile = UserDefaults.standard.object(forKey: unwrappedUserProfilePath),
              let validActiveUserProfileDictionary = userDefaultsUserProfile as? [String:Any],
              let validActiveUserProfile = UserProfile(dictionary: validActiveUserProfileDictionary) else {
            print("Couldn't generate a user profile stored in defaults, backing out of view did load now.")
            return
        }
        
        self.activeUser = validActiveUserProfile
        
        guard let unwrappedMatchedCoder = self.matchedCoderUserProfile else {
            print("No coder uid passed into the details view controller, backing out of view did load now.")
            return
        }
        
        self.conversationsRef = Database.database().reference(withPath: unwrappedConversationsPath)
        self.userProfileRef = Database.database().reference(withPath: unwrappedUserProfilePath)
        self.coderProfileRef = Database.database().reference(withPath: unwrappedCoderProfilePath)
        
        guard let unwrappedCoderProfileRef = self.coderProfileRef else {
            print("Couldn't initialize a firebase reference for a coding matching profile, backing out of view did load.")
            return
        }
        
        self.getActiveUserCoderMatchingProfile(unwrappedCoderProfileRef: unwrappedCoderProfileRef, activeUserUid: validActiveUserProfile.uid, completion: { activeUserCoderMatchingProfile in
            guard let unwrappedActiveUserCoderProfile = activeUserCoderMatchingProfile else {
                return
            }
            self.getMatchedUserCodingProfile(unwrappedCoderProfileRef: unwrappedCoderProfileRef, matchingUserUid: unwrappedMatchedCoder.uid, completion: { matchedUserCoderProfile in
                guard let unwrappedMatchedUserCoderProfile = matchedUserCoderProfile else {
                    return
                }
                var percentMatched : Float?
                do {
                    percentMatched = try self.generatePercentMatchedValue(profile1: unwrappedActiveUserCoderProfile, profile2: unwrappedMatchedUserCoderProfile)
                } catch (let error) {
                    print(error)
                }
                guard let unwrappedPercentMatched = percentMatched else {
                    print("No percent match found for the active and matched user coding profiles, backing out now.")
                    return
                }
                self.updateMatchedCoderProfileLabels(matchedCoderProfile: unwrappedMatchedUserCoderProfile, matchedUserProfile: unwrappedMatchedCoder, percentMatch: unwrappedPercentMatched)
            })
        })
    }
    
    @IBOutlet weak var lblMatchedCoderName: UILabel!
    
    @IBOutlet weak var lblPercentMatch: UILabel!
    
    @IBOutlet weak var lblIde: UILabel!
    
    @IBOutlet weak var lblOs: UILabel!
    
    @IBOutlet weak var lblFont: UILabel!
    
    @IBOutlet weak var lblLanguage: UILabel!
    
    @IBOutlet weak var lblTheme: UILabel!
    
    @IBOutlet weak var lblBrowser: UILabel!
    
    @IBAction func btnStartConversation(_ sender: UIButton) {
        // MAGIC!
        
        guard let unwrappedActiveUser = self.activeUser,
              let unwrappedMatchedUser = self.matchedCoderUserProfile else {
            print("Can't start a new conversation as either the active or matched user profile is nil.")
            return
        }
        
        let layout = UICollectionViewFlowLayout()
        
        let controller = ChatLogViewController(collectionViewLayout: layout)
        
        controller.conversation = nil
        controller.friendProfile = unwrappedMatchedUser
        controller.activeUser = unwrappedActiveUser
        controller.conversationsRef = self.conversationsRef
        controller.conversationOfFriend = nil
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func updateMatchedCoderProfileLabels(matchedCoderProfile: CoderMatchingProfile, matchedUserProfile: UserProfile, percentMatch: Float) {
        self.lblMatchedCoderName.text = "\(matchedUserProfile.firstName)" + " " + "\(matchedUserProfile.lastName)"
        self.lblPercentMatch.text = "Percent match: \(percentMatch)"
        self.lblIde.text = "Favorite IDE: \(matchedCoderProfile.favIDE)"
        self.lblOs.text = "Favorite OS: \(matchedCoderProfile.favOS)"
        self.lblFont.text = "Favorite font: \(matchedCoderProfile.favFont)"
        self.lblLanguage.text = "Favorite language: \(matchedCoderProfile.favLanguage)"
        self.lblTheme.text = "Favorite theme: \(matchedCoderProfile.favTheme)"
        self.lblBrowser.text = "Favorite browser: \(matchedCoderProfile.favBrowser)"
    }
    
    func generatePercentMatchedValue(profile1: CoderMatchingProfile, profile2: CoderMatchingProfile) throws -> Float {
        let coderProfileDictionary1 = profile1.toDictionary()
        let coderProfileDictionary2 = profile2.toDictionary()
        
        var numMatchedProfileValues = 0
        let totalProfileCategories = coderProfileDictionary1.count
        
        if totalProfileCategories == 0 {
            throw CodeupError.zeroDivision
        }
        
        for (key, value) in coderProfileDictionary1 {
            guard let unwrappedDictionaryValue2 = coderProfileDictionary2[key] else {
                print("Couldn't find key value pair in profile dictionary 2 for key: \(key)")
                throw CodeupError.invalidKey
            }
            if unwrappedDictionaryValue2 == value {
                numMatchedProfileValues += 1
            }
        }
        return (Float(numMatchedProfileValues) / Float(totalProfileCategories)) * 100.0
    }
    
    func getActiveUserCoderMatchingProfile(unwrappedCoderProfileRef: DatabaseReference, activeUserUid: String, completion: @escaping (CoderMatchingProfile?) -> Void) {
        unwrappedCoderProfileRef.child(activeUserUid).observe(.value, with: { snapshot in
            guard let validActiveUserCodingProfile = CoderMatchingProfile(snapshot: snapshot) else {
                print("Couldn't retrieve a valid coder matching profile for the active user, backing out now.")
                return
            }
            completion(validActiveUserCodingProfile)
        })
    }
    
    func getMatchedUserCodingProfile(unwrappedCoderProfileRef: DatabaseReference, matchingUserUid: String, completion: @escaping (CoderMatchingProfile?) -> Void) {
        unwrappedCoderProfileRef.child(matchingUserUid).observe(.value, with: { snapshot in
            guard let validMatchingUserCoderProfile = CoderMatchingProfile(snapshot: snapshot) else {
                print("Couldn't construct a valid coder matching profile for the matched user, backing out now.")
                return
            }
            completion(validMatchingUserCoderProfile)
        })
    }
}
