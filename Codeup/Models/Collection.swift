//
//  Collection.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/19/21.
//

import Foundation

enum Collections {
    case UserProfile
    case CoderMatchingProfile
    case Conversations
}

let DatabaseCollections = [
    Collections.UserProfile: "userProfile",
    Collections.CoderMatchingProfile: "coderMatchingProfile",
    Collections.Conversations: "conversations"
]
