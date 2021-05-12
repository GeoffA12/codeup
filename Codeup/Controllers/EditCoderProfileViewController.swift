//
//  EditCoderProfileViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/20/21.
//

import UIKit
import DropDown
import Firebase

class EditCoderProfileViewController: UIViewController {
    
    var database: DatabaseReference?
    
    var userProfile: UserProfile?
    
    var updateMode: Bool?
    
    let ideDropDown = DropDown()
    let osDropDown = DropDown()
    let languageDropDown = DropDown()
    let fontDropDown = DropDown()
    let themeDropDown = DropDown()
    let browserDropDown = DropDown()
    
    var ideSelection: String?
    var osSelection: String?
    var languageSelection: String?
    var fontSelection: String?
    var themeSelection: String?
    var browserSelection: String?
    
    // TODO: To implement the update feature for this form/view, connect each UI Button as a label as well, and change the button title label upon getting back a coder matching profile
    // from Firebase

    override func viewDidLoad() {
        super.viewDidLoad()
        ideDropDown.dataSource = ideData
        osDropDown.dataSource = osData
        languageDropDown.dataSource = languageData
        fontDropDown.dataSource = fontData
        themeDropDown.dataSource = themeData
        browserDropDown.dataSource = browserData
        
        var coderMatchingProfilePath: String?
        var userProfilePath: String?

        do {
            coderMatchingProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.CoderMatchingProfile])
            userProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
        } catch (let error) {
            print(error)
        }
        
        guard let unwrappedUserProfilePath = userProfilePath, let unwrappedUserProfile = UserDefaults.standard.object(forKey: unwrappedUserProfilePath) else {
            print("User defaults user profile could not be found, exiting view did load without setting db path.")
            return
        }
        
        guard let validUserProfileValue = unwrappedUserProfile as? [String:Any], let validUserProfile = UserProfile(dictionary: validUserProfileValue) else {
            print("Couldn't convert the user defaults return value: \(unwrappedUserProfile) into a valid user profile object, backing out of viewDidLoad().")
            return
        }
        
        self.userProfile = validUserProfile
        
        guard let unwrappedCoderMatchingProfilePath = coderMatchingProfilePath else {
            print("Could not find database path \(coderMatchingProfilePath) in EditCoderProfile, backing out of viewDidLoad().")
            return
        }
        
        self.database = Database.database().reference(withPath: unwrappedCoderMatchingProfilePath)
        
        guard let unwrappedCoderMatchingProfileRef = self.database else {
            print("Couldn't fetch a valid firebase reference for a coder matching profile collection.")
            return
        }
        
        unwrappedCoderMatchingProfileRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.hasChild(validUserProfile.uid) {
                let child = snapshot.childSnapshot(forPath: validUserProfile.uid)
                let coderMatchingProfileFromSnapshot = CoderMatchingProfile(snapshot: child)
                guard let validCoderMatchingProfile = coderMatchingProfileFromSnapshot else {
                    print("Couldn't construct a valid coder matching profile from snapshot data.")
                    return
                }
                self.ideSelection = validCoderMatchingProfile.favIDE
                self.osSelection = validCoderMatchingProfile.favOS
                self.languageSelection = validCoderMatchingProfile.favLanguage
                self.fontSelection = validCoderMatchingProfile.favFont
                self.themeSelection = validCoderMatchingProfile.favTheme
                self.browserSelection = validCoderMatchingProfile.favBrowser
                
                self.btnIDEOutlet.setTitle(self.ideSelection, for: .normal)
                self.btnOSOutlet.setTitle(self.osSelection, for: .normal)
                self.btnLanguageOutlet.setTitle(self.languageSelection, for: .normal)
                self.btnFontOutlet.setTitle(self.fontSelection, for: .normal)
                self.btnThemeOutlet.setTitle(self.themeSelection, for: .normal)
                self.btnBrowserOutlet.setTitle(self.browserSelection, for: .normal)
                self.updateMode = true
            } else {
                print("No valid coder profile found.")
                self.updateMode = false
            }
        })
    }
    
    @IBAction func btnSaveMatchingProfile(_ sender: UIButton) {
        guard let unwrappedIdeSelection = self.ideSelection,
              let unwrappedOsSelection = self.osSelection,
              let unwrappedLanguageSelection = self.languageSelection,
              let unwrappedFontSelection = self.fontSelection,
              let unwrappedThemeSelection = self.themeSelection,
              let unwrappedBrowserSelection = self.browserSelection else {
            print("One of the input fields is nil, cannot register matching profile.")
            let matchingCoderProfileFormAlert = UIAlertController(title: "Save failed.", message: "All fields must be selected prior to saving coding matching profile.", preferredStyle: .alert)
            matchingCoderProfileFormAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(matchingCoderProfileFormAlert, animated: true, completion: nil)
            return
        }
        
        guard let unwrappedDatabase = self.database, let unwrappedUserProfile = self.userProfile, let unwrappedUpdateMode = self.updateMode else {
            return
        }
        let coderMatchingProfileForPersistence = CoderMatchingProfile(key: unwrappedUserProfile.uid, favIDE: unwrappedIdeSelection, favOS: unwrappedOsSelection, favLanguage: unwrappedLanguageSelection, favFont: unwrappedFontSelection, favTheme: unwrappedThemeSelection, favBrowser: unwrappedBrowserSelection)
        if !unwrappedUpdateMode {
            unwrappedDatabase.child(unwrappedUserProfile.uid).setValue(coderMatchingProfileForPersistence.toAnyObject())
        } else {
            unwrappedDatabase.child(unwrappedUserProfile.uid).updateChildValues(["favIDE": coderMatchingProfileForPersistence.favIDE, "favOS": coderMatchingProfileForPersistence.favOS, "favLanguage": coderMatchingProfileForPersistence.favLanguage, "favFont": coderMatchingProfileForPersistence.favFont, "favTheme": coderMatchingProfileForPersistence.favTheme, "favBrowser": coderMatchingProfileForPersistence.favBrowser])
        }
        
        let confirmationAlert = UIAlertController(title: "Save successful.", message: "Coder matching profile successfully saved.", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "OK", style: .default))
        
        self.present(confirmationAlert, animated: true)
    }
    
    @IBOutlet var btnIDEOutlet: UIButton!
    @IBOutlet var btnOSOutlet: UIButton!
    @IBOutlet var btnLanguageOutlet: UIButton!
    @IBOutlet var btnFontOutlet: UIButton!
    @IBOutlet var btnThemeOutlet: UIButton!
    @IBOutlet var btnBrowserOutlet: UIButton!
    @IBAction func btnIDETapped(_ sender: UIButton) {
        var dropDown: DropDown? = nil
        switch sender.tag {
            case 0:
                dropDown = self.ideDropDown
            case 1:
                dropDown = self.osDropDown
            case 2:
                dropDown = self.languageDropDown
            case 3:
                dropDown = self.fontDropDown
            case 4:
                dropDown = self.themeDropDown
            case 5:
                dropDown = self.browserDropDown
            default:
                print("Unknown tag sent: \(sender.tag)")
        }
        
        guard let unwrappedDropdown = dropDown else {
            print("Unknown tag was sent to action handler. Returning.")
            return
        }
        configureDropdown(sender: sender, dropDown: unwrappedDropdown)
    }
    
    func configureDropdown(sender: UIButton, dropDown: DropDown) {
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        guard let buttonTitleLabel = sender.titleLabel,
              let buttonTitleLabelText = buttonTitleLabel.text else {
            print("The button doesn't have a title label that can be used to configure the matching profile")
            return
        }
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let _ = self else { return }
            sender.setTitle(item, for: .normal)
            switch sender.tag {
                case 0:
                    self.self?.ideSelection = dropDown.dataSource[index]
                case 1:
                    self.self?.osSelection = dropDown.dataSource[index]
                case 2:
                    self.self?.languageSelection = dropDown.dataSource[index]
                case 3:
                    self.self?.fontSelection = dropDown.dataSource[index]
                case 4:
                    self.self?.themeSelection = dropDown.dataSource[index]
                case 5:
                    self.self?.browserSelection = dropDown.dataSource[index]
                default:
                    print("Unknown tag sent: \(sender.tag)")
            }
        }
    }
}
