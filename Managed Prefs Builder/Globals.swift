//
//  Globals.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/16/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Foundation

struct preferenceKeys {
    static var tableArray: [String]?
    static var valuePairs = [String:[String:Any]]()
}

struct tab {
    static var current = ""
}

let userDefaults = UserDefaults.standard
// determine if we're using dark mode
var isDarkMode: Bool {
    let mode = userDefaults.string(forKey: "AppleInterfaceStyle")
    return mode == "Dark"
}
