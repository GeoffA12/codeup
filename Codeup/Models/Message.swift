//
//  Message.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/25/21.
//

import Foundation

struct Message {
    var text: String
    var friend: Friend
    var date: String
    
    init(text: String, friend: Friend, date: String) {
        self.text = text
        self.friend = friend
        self.date = date
    }
    
    init?(dictionary: [String:Any]) {
        guard let text = dictionary["text"],
              let friend = dictionary["friend"],
              let date = dictionary["date"],
              let validText = text as? String,
              let validDate = date as? String,
              let validFriendDictionary = friend as? [String:String] else {
            print("Couldn't construct a valid Message from input dictionary: \(dictionary)")
            return nil
        }
        
        guard let validFriend = Friend(dictionary: validFriendDictionary) else {
            return nil
        }
        
        self.text = validText
        self.friend = validFriend
        self.date = validDate

    }
    
    func isSender(uid: String) -> Bool {
        return self.friend.uid == uid
    }
    
//    static func getMessagesFromAnyObjectArray(array: [AnyObject]) -> [Message]? {
//        var messages: [Message] = []
//        for data in array {
//            for key in data {
//
//            }
//            guard let message = data as? Message else {
//                print("Not a valid message: \(data)")
//                return nil
//            }
//            messages.append(message)
//        }
//        return messages
//    }
    
    // TODO: Remove if not using this
    func toAnyObject() -> Any {
        return [
            "text": self.text as NSObject,
            "friend": self.friend.toDictionary(),
            "date": self.date
        ]
    }
    
    func toDictionary() -> [String:Any] {
        return [
            "text": self.text,
            "friend": self.friend.toDictionary(),
            "date": self.date
        ]
    }
}
