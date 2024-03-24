//
//  KeysVC.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa
import Foundation

protocol SendingKeyInfoDelegate {
    func sendKeyInfo(keyInfo: TheKey)
}

class KeysVC: NSViewController {
    
    var delegate: SendingKeyInfoDelegate? = nil
    
    @IBOutlet weak var keys_TabView: NSTabView!
    
    @IBOutlet weak var keyRequired_Button: NSButton!
    @IBOutlet weak var keyName_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    
    @IBOutlet weak var keyDescription_TextField: NSTextField!
    @IBOutlet weak var keyInfoText_TextField: NSTextField!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
    @IBOutlet weak var add_Button: NSButton!
    @IBOutlet weak var cancel_Button: NSButton!
    
    // advanced key tab - start
    @IBOutlet weak var advIntegerList_Label: NSTextField!
    
    @IBOutlet var enum_titles_TextView: NSTextView!
    @IBOutlet var enum_TextView: NSTextView!
//    @IBOutlet weak var enum_TextField: NSTextField!
    
    var existingKey: TheKey?
    var existingKeyId = ""
    
    @IBAction func selectKeyType_Action(_ sender: NSPopUpButton) {
        print("[selectKeyType_Action] key type: \(sender.title)")
        let whichKey = sender.titleOfSelectedItem ?? "unknown"
        switch whichKey {
        case "array (from list)", "integer (from list)":
            add_Button.title = "Set"
            keys_TabView.selectTabViewItem(at: 1)
            print("updating enum_title for key \(keyName_TextField.stringValue)")
            
            print("updating enum for key \(keyName_TextField.stringValue)")
        default:
            add_Button.title = "Add"
            keys_TabView.selectTabViewItem(at: 0)
        }

    }
    
    @IBAction func cancel_Action(_ sender: Any) {
        keyRequired_Button.state = .off
        keyFriendlyName_TextField.stringValue = ""
        keyDescription_TextField.stringValue = ""
        keyInfoText_TextField.stringValue = ""
        enum_titles_TextView.string = ""
        enum_TextView.string = ""
        dismiss(self)
    }
    
    
    @IBAction func add_Action(_ sender: NSButton) {
        let whichTab = keys_TabView.selectedTabViewItem?.label ?? "unknown"
        let keyType =  keyType_Button.titleOfSelectedItem ?? "unknown"
        
        if keyName_TextField.stringValue == "" {
            Alert.shared.display(header: "", message: "A key must be provided")
            return
        }
        if keyType == "unknown" || keyType == "Select Key Type" {
            Alert.shared.display(header: "", message: "A key type must be selected")
            return
        }
        
        if whichTab == "main" {
            if keyFriendlyName_TextField.stringValue == "" {
                keyFriendlyName_TextField.stringValue = keyName_TextField.stringValue
            }
            
            
            if keyDescription_TextField.stringValue == "" {
                keyFriendlyName_TextField.stringValue = keyName_TextField.stringValue
            }
            let keyId = (existingKeyId == "") ? UUID().uuidString:existingKeyId
            let currentKey = TheKey(id: keyId, type: keyType_Button.titleOfSelectedItem ?? "unknown", name: keyName_TextField.stringValue, required: (keyRequired_Button.state == .on) ? true:false, friendlyName: keyFriendlyName_TextField.stringValue, desc: keyDescription_TextField.stringValue, infoText: keyInfoText_TextField.stringValue, listOfOptions: enum_titles_TextView.string, listOfValues: enum_TextView.string)
            print("[set_Action] whichTab: \(whichTab)")
            delegate?.sendKeyInfo(keyInfo: currentKey)
            dismiss(self)
        } else {
            
            // verify enum_titles and enum have the same number of values
            let enum_titlesTmp = enum_titles_TextView.string.replacingOccurrences(of: "\n", with: ",")
            let enum_titlesArray = enum_titlesTmp.split(separator: ",")
            let enumTmp          = enum_TextView.string.replacingOccurrences(of: "\n", with: ",")
            let enumArray        = enumTmp.split(separator: ",")
            if enum_titlesArray.count == enumArray.count {
    //            validate integers
                if "\(keyType_Button.titleOfSelectedItem!)" == "integer (from list)" {
                    let validateInput       = "\(enum_TextView.string)".replacingOccurrences(of: "\"", with: "")
                    let validateInputString = validateInput.replacingOccurrences(of: "\n", with: ",")
                    let validateInputArray  = validateInputString.split(separator: ",")
                    for theValue in validateInputArray {
                        let intTest = theValue.replacingOccurrences(of: " ", with: "")
                        if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: "\(intTest)")) {
                            Alert.shared.display(header: "Error", message: "Found '\(intTest)' and only integers are allowed.")
                            return
                        }
                    }
                }

                add_Button.title = "Add"
                self.keys_TabView.selectTabViewItem(at: 0)
                
            } else {
                Alert.shared.display(header: "Attention", message: "Number of items defined in list of options and number of items defined in the value list must be equal.\n\tCount of options: \(enum_titlesArray.count)\n\tCount of values: \(enumArray.count)")
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enum_titles_TextView.font = NSFont(name: "Courier", size: 14.0)
        enum_titles_TextView.textColor = isDarkMode ? NSColor.white:NSColor.black
        enum_TextView.font = NSFont(name: "Courier", size: 14.0)
        enum_TextView.textColor = isDarkMode ? NSColor.white:NSColor.black
        
        if existingKey?.name ?? "" != "" {
            keyType_Button.selectItem(withTitle: existingKey?.type ?? "Select Key Type")
            keyName_TextField.stringValue = existingKey?.name ?? ""
            keyFriendlyName_TextField.stringValue = existingKey?.friendlyName ?? ""
            keyDescription_TextField.stringValue = existingKey?.desc ?? ""
            keyInfoText_TextField.stringValue = existingKey?.infoText ?? ""
            keyRequired_Button.state = (existingKey?.required ?? false) ? .on:.off
            enum_titles_TextView.string = existingKey?.listOfOptions ?? ""
            enum_TextView.string = existingKey?.listOfValues ?? ""
            
            add_Button.title = "Update"
        }
        
    }
    

    override func viewWillAppear() {

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}
