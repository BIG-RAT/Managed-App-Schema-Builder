//
//  Copyright 2026 Jamf. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // quit the app if the window is closed - start
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }
    // quit the app if the window is closed - end
    
    @IBAction func quit(_ sender: Any) {
        NotificationCenter.default.post(name: .quitNow, object: self)
    }
    
    @IBAction func newSchema(_ sender: Any) {
        NotificationCenter.default.post(name: .newSchema, object: self)
    }
    
    @IBAction func importSchema(_ sender: Any) {
        NotificationCenter.default.post(name: .importSchema, object: self)
    }
    
    @IBAction func showLogFolder(_ sender: Any) {
        if (FileManager.default.fileExists(atPath: Log.path!)) {
            NSWorkspace.shared.open(URL(fileURLWithPath: Log.path!))
        } else {
            _ = Alert.shared.display(header: "Alert", message: "There are currently no log files to display.", secondButton: "")
        }
    }


}

