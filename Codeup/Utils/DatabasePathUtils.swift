//
//  DatabasePathUtils.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/19/21.
//

import Foundation

struct DatabasePathUtils {
    static func checkDatabasePathExists(path: String?) throws -> String {
        guard let unwrappedPath = path else {
            throw CodeupError.invalidDatabasePath
        }
        return unwrappedPath
    }
}

