//
//  Alert.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/9/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa

class Alert: NSObject {
    func display(header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
}
