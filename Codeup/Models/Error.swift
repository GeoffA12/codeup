//
//  Error.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/18/21.
//

import Foundation

enum CodeupError: Error {
    case invalidAddressInput
    case invalidDatabasePath
    case invalidKey
    case zeroDivision
}
