//
//  Globals.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/16/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Foundation

struct tab {
    static var current = ""
}

let defaults = UserDefaults.standard
var isRunning              = false
var didRun                 = false

// determine if we're using dark mode
var isDarkMode: Bool {
    let mode = defaults.string(forKey: "AppleInterfaceStyle")
    return mode == "Dark"
}

struct AppInfo {
    static let dict          = Bundle.main.infoDictionary!
    static let version       = dict["CFBundleShortVersionString"] as! String
    static let build         = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    static let name          = dict["CFBundleExecutable"] as! String
    
    static let appSupport    = NSHomeDirectory() + "/Library/Application Support/"    
}

struct JamfProServer {
    static var accessToken  = ""
    static var authExpires  = 30.0
    static var currentCred  = ""
    static var tokenCreated = Date()
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var build        = ""
    static var version      = ""
    static var authType     = ""
//    static var destination  = ""
    static var displayName  = ""
    static var username     = ""
    static var password     = ""
    static var useApiClient = 0
    static var authCreds    = ""
    static var base64Creds  = ""        // used if we want to auth with a different account
    static var validToken   = false
    static var tokenExpires = ""
    
    static var url          = ""
}

public func timeDiff(startTime: Date) -> (Int, Int, Int, Double) {
    let endTime = Date()

    let components = Calendar.current.dateComponents([
        .hour, .minute, .second, .nanosecond], from: startTime, to: endTime)
    var diffInSeconds = Double(components.hour!)*3600 + Double(components.minute!)*60 + Double(components.second!) + Double(components.nanosecond!)/1000000000
    diffInSeconds = Double(round(diffInSeconds * 1000) / 1000)

    return (Int(components.hour!), Int(components.minute!), Int(components.second!), diffInSeconds)
}
