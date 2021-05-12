//
//  Conversation.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/25/21.
//

import Foundation

struct Friend {
    var uid: String
    var firstName: String
    var lastName: String
    
    init(uid: String, firstName: String, lastName: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
    }
    
    init?(dictionary: [String:String]) {
        guard let uid = dictionary["uid"],
              let firstName = dictionary["firstName"],
              let lastName = dictionary["lastName"] else {
            print("Couldn't construct a valid friend object given input dictionary: \(dictionary)")
            return nil
        }
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
    }
    
    // TODO: Remove if not using this
    func toAnyObject() -> Any {
        return [
            "uid": self.uid as NSObject,
            "firstName": self.firstName as NSObject,
            "lastName": self.lastName as NSObject
        ]
    }
    
    func toDictionary() -> [String:String] {
        return [
            "uid": self.uid,
            "firstName": self.firstName,
            "lastName": self.lastName
        ]
        
    }
}
