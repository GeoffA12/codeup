//
//  Conversation.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/26/21.
//

import Foundation
import Firebase

struct Conversation {
    var key: String
    var startDate: String
    var messages: [Message]
    var friendProfile: UserProfile
    
    init(key: String, startDate: String, messages: [Message], friendProfile: UserProfile) {
        self.key = key
        self.startDate = startDate
        self.messages = messages
        self.friendProfile = friendProfile
    }
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String:AnyObject],
              let startDate = value["startDate"] as? String,
              let messages = value["messages"] as? [[String:Any]],
              let friendProfile = value["friendProfile"] as? [String:Any] else {
            print("Couldn't unwrap snapshot data from value: \(snapshot.value)")
            return nil
        }
        
        var validMessages: [Message] = []
        
        for dictionary in messages {
            guard let validMessage = Message(dictionary: dictionary) else {
                return nil
            }
            validMessages.append(validMessage)
        }
        
        guard let validFriendProfile = UserProfile(dictionary: friendProfile) else {
            print("Couldn't construct friend profile from conversation entity, backing out of constructor now.")
            return nil
        }
        
        self.key = snapshot.key
        self.startDate = startDate
        self.messages = validMessages
        self.friendProfile = validFriendProfile
    }
    
    func toAnyObject() -> Any {
        let messageObjects = messages.map({ $0.toDictionary() })
        return [
            "startDate": self.startDate,
            "messages": messageObjects,
            "friendProfile": self.friendProfile.toDictionary()
        ]
    }
    
    func getLatestMessage() -> Message? {
        if self.messages.count == 0 {
            print("Invalid messages array for this conversation, no messages have been sent so I cannot return latest message date")
            return nil
        } else {
            let latestMessage = self.messages[self.messages.count - 1]
            return latestMessage
        }
    }
}
