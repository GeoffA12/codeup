//
//  UserProfile.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/18/21.
//

import Foundation
import Firebase

struct UserProfile {
    
    let ref: DatabaseReference?
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    let age: Int
    let address: Address
    
    init(uid: String, firstName: String, lastName: String, email: String, age: Int, address: Address) {
        self.ref = nil
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.age = age
        self.address = address
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let firstName = value["firstName"] as? String,
            let lastName = value["lastName"] as? String,
            let email = value["email"] as? String,
            let age = value["age"] as? Int,
            let address = value["address"] else {
            print("Can't convert snapshot values to a valid user profile.")
            return nil
        }
        
        guard let city = address["city"] as? String,
              let state = address["state"] as? String,
              let street_address = address["street_address"] as? String,
              let latitude = address["latitude"] as? Double,
              let longitude = address["longitude"] as? Double else {
            print("Invalid address input")
            return nil
        }
        
        let validAddress = Address(state: state, street_address: street_address, city: city, latitude: latitude, longitude: longitude)
        self.ref = snapshot.ref
        self.uid = snapshot.key
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.age = age
        self.address = validAddress
    }
    
    init?(dictionary: [String:Any]) {
        guard let unwrappedUid = dictionary["uid"],
              let unwrappedFirstName = dictionary["firstName"],
              let unwrappedLastName = dictionary["lastName"],
              let unwrappedEmail = dictionary["email"],
              let unwrappedAge = dictionary["age"],
              let unwrappedAddress = dictionary["address"],
              let validUid = unwrappedUid as? String,
              let validFirstName = unwrappedFirstName as? String,
              let validLastName = unwrappedLastName as? String,
              let validEmail = unwrappedEmail as? String,
              let validAge = unwrappedAge as? Int,
              let validAddressValue = unwrappedAddress as? [String:Any],
              let validAddress = Address(dictionary: validAddressValue) else {
            print("Dictionary data: \(dictionary) was not valid, can't construct a UserProfile instance.")
            return nil
        }
        self.ref = nil
        self.uid = validUid
        self.firstName = validFirstName
        self.lastName = validLastName
        self.email = validEmail
        self.age = validAge
        self.address = validAddress
    }
    
    func toAnyObject() -> Any {
        return [
            "firstName": self.firstName as NSObject,
            "lastName": self.lastName as NSObject,
            "email": self.email as NSObject,
            "age": self.age as NSObject,
            "address": self.address.toAnyObject()
        ]
    }
    
    func toDictionary() -> [String:Any] {
        return [
            "uid": self.uid,
            "firstName": self.firstName,
            "lastName": self.lastName,
            "email": self.email,
            "age": self.age,
            "address": self.address.toUserProfileDictionary()
        ]
    }
    
    func toUserDefaultsDictionary() -> [String:Any?] {
        return [
            "uid": self.uid,
            "firstName": self.firstName,
            "lastName": self.lastName,
            "email": self.email,
            "age": self.age,
            "address": self.address.toUserProfileDictionary()
        ]
    }
}
