//
//  MatchingProfile.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/20/21.
//

import Foundation
import Firebase

struct CoderMatchingProfile {
    var ref: DatabaseReference?
    var key: String
    var favIDE: String
    var favOS: String
    var favLanguage: String
    var favFont: String
    var favTheme: String
    var favBrowser: String
    
    init(key: String, favIDE: String, favOS: String, favLanguage: String, favFont: String, favTheme: String, favBrowser: String) {
        self.ref = nil
        self.key = key
        self.favIDE = favIDE
        self.favOS = favOS
        self.favLanguage = favLanguage
        self.favFont = favFont
        self.favTheme = favTheme
        self.favBrowser = favBrowser
    }
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String:AnyObject],
              let favIDE = value["favIDE"] as? String,
              let favOS = value["favOS"] as? String,
              let favLanguage = value["favLanguage"] as? String,
              let favFont = value["favFont"] as? String,
              let favTheme = value["favTheme"] as? String,
              let favBrowser = value["favBrowser"] as? String else {
            print("Couldn't convert data snapshot into a valid coder matching profile.")
            return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.favIDE = favIDE
        self.favOS = favOS
        self.favLanguage = favLanguage
        self.favFont = favFont
        self.favTheme = favTheme
        self.favBrowser = favBrowser
    }
    
    func toAnyObject() -> Any {
        return [
            "favIDE": self.favIDE as NSObject,
            "favOS": self.favOS as NSObject,
            "favLanguage": self.favLanguage as NSObject,
            "favFont": self.favFont as NSObject,
            "favTheme": self.favTheme as NSObject,
            "favBrowser": self.favBrowser as NSObject
        ]
    }
    
    func toDictionary() -> [String:String] {
        return [
            "favIDE": self.favIDE,
            "favOS": self.favOS,
            "favLanguage": self.favLanguage,
            "favFont": self.favFont,
            "favTheme": self.favTheme,
            "favBrowser": self.favBrowser
        ]
    }
}
