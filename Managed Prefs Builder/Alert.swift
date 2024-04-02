//
//  Alert.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/9/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa

class Alert: NSObject {
    
    static let shared = Alert()
    private override init() { }
    
    func display(header: String, message: String, secondButton: String = "") -> String {
        NSApplication.shared.activate(ignoringOtherApps: true)
        var selected = ""
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        let okButton = (secondButton == "Use Anyway") ? dialog.addButton(withTitle: "Cancel"):dialog.addButton(withTitle: "OK")
        if secondButton != "" {
            let otherButton = dialog.addButton(withTitle: secondButton)
            otherButton.keyEquivalent = "\(secondButton.lowercased().first ?? "c")"
            okButton.keyEquivalent = "\r"
        }
        
        let theButton = dialog.runModal()
        switch theButton {
        case .alertFirstButtonReturn:
            selected = "OK"
        default:
            selected = secondButton
        }
        return selected
    }
}
