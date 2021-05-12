//
//  User.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/18/21.
//

import Foundation
import Firebase

struct User {
    
    let uid: String
    let email: String
    
    init(uid: String, firstName: String, lastName: String, email: String, password: String, age: Int, address: Address) {
        self.uid = uid
        self.email = email
    }
    
    init(authData: Firebase.User) {
        self.uid = authData.uid
        self.email = authData.email!
    }
    
}
