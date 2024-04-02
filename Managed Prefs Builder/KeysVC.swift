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
    
    @IBOutlet weak var main_Scrollview: NSScrollView!
    
    @IBOutlet weak var keyRequired_Button: NSButton!
    @IBOutlet weak var keyName_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    
    @IBOutlet weak var keyDescription_TextField: NSTextField!
    @IBOutlet weak var keyInfoText_TextField: NSTextField!
    
    @IBOutlet weak var moreInfo_TextField: NSTextField!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
    @IBOutlet weak var add_Button: NSButton!
    @IBOutlet weak var cancel_Button: NSButton!
    
    @IBOutlet weak var listHeaderLabel_TextField: NSTextField!
    @IBOutlet weak var headerOrPlaceholder_TextField: NSTextField!
    
    @IBOutlet weak var listOptions_TextField: NSTextField!
    @IBOutlet weak var listValues_TextField: NSTextField!
    
    @IBOutlet weak var enum_titles_ScrollView: NSScrollView!
    @IBOutlet weak var enum_ScrollView: NSScrollView!
    
    @IBOutlet var enum_titles_TextView: NSTextView!
    @IBOutlet var enum_TextView: NSTextView!
    
    var existingKey: TheKey?
    var existingKeyId = ""
    var keyIndex      = 0
    var whichKeyType  = ""
    var scrollAdjust: CGFloat = 0.0
    var windowFrameH: CGFloat = 0.0
    var scrollFrameH: CGFloat = 0.0
    
    @IBAction func selectKeyType_Action(_ sender: NSPopUpButton) {
//        print("[selectKeyType_Action] key type: \(sender.title)")
        var frame = self.view.window?.frame
        let currentWidth = max(651, frame?.width ?? 651)
        frame?.size = NSSize(width: currentWidth, height: 525)
        var hidden = true
        let whichKey = sender.titleOfSelectedItem ?? "unknown"
        switch whichKey {
        case "string (from list)", "integer (from list)":
            hidden = false
//            preferredContentSize = CGSize(width: 651, height: 700)
            frame?.size = NSSize(width: currentWidth, height: 750)
//            scrollAdjust = windowFrameH-main_Scrollview.contentView.bounds.size.height  //200
            listOptions_TextField.isHidden = false
            listHeaderLabel_TextField.isHidden = true
            headerOrPlaceholder_TextField.isHidden = true
//            print("updating enum_title for key \(keyName_TextField.stringValue)")
//            print("updating enum for key \(keyName_TextField.stringValue)")
        case "string array", "integer array":
//            preferredContentSize = CGSize(width: 651, height: 525)
            
//            frame?.size = NSSize(width: 651, height: 525)
//            scrollAdjust = windowFrameH-main_Scrollview.contentView.bounds.size.height  //142
            listOptions_TextField.isHidden = true
            listHeaderLabel_TextField.isHidden = false
            headerOrPlaceholder_TextField.isHidden = false
        case "boolean":
            listOptions_TextField.isHidden = true
            listHeaderLabel_TextField.isHidden = true
            headerOrPlaceholder_TextField.isHidden = true
        default:
//            scrollAdjust = windowFrameH-main_Scrollview.contentView.bounds.size.height  //92
            listOptions_TextField.isHidden = hidden
            listHeaderLabel_TextField.stringValue = "Placeholder:"
            listHeaderLabel_TextField.isHidden = false
            headerOrPlaceholder_TextField.isHidden = false
        }
//        print("[selectKey_Action] keyName_TextField.frame.maxY: \(keyName_TextField.frame.maxY)")
//        print("[selectKey_Action] windowFrameH: \(windowFrameH)")
//        print("[selectKey_Action] Scrollview.contentView.bounds.size.height: \(main_Scrollview.contentView.bounds.size.height)")
        scrollAdjust = (keyName_TextField.frame.maxY+34) - main_Scrollview.contentView.bounds.size.height
        self.view.window?.setFrame(frame!, display: true)
        main_Scrollview.contentView.scroll(to: NSPoint(x: 1.0, y: scrollAdjust))
        listValues_TextField.isHidden = hidden
        enum_titles_ScrollView.isHidden = hidden
        enum_ScrollView.isHidden = hidden
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
        
        if moreInfo_TextField.stringValue != "" {
            if !urlValidation() {
                return
            }
        }
        
        let keyType =  keyType_Button.titleOfSelectedItem ?? "unknown"
        
        if keyName_TextField.stringValue == "" {
            _ = Alert.shared.display(header: "", message: "A key must be provided")
            return
        }
        if keyType == "unknown" || keyType == "Select Key Type" {
            _ = Alert.shared.display(header: "", message: "A key type must be selected")
            return
        }
        
        if keyFriendlyName_TextField.stringValue == "" {
            keyFriendlyName_TextField.stringValue = keyName_TextField.stringValue
        }
            
        if keyDescription_TextField.stringValue == "" {
            keyFriendlyName_TextField.stringValue = keyName_TextField.stringValue
        }
        let keyId = (existingKeyId == "") ? UUID().uuidString:existingKeyId
        var listType = ""
        if ["integer array", "string array"].contains(keyType_Button.titleOfSelectedItem) {
            listType = ( keyType_Button.titleOfSelectedItem == "integer array" ) ? "integer":"string"
        }
//            print("[set_Action] whichTab: \(whichTab)")
            
        if ["string (from list)", "integer (from list)"].contains(keyType) {
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
                            _ = Alert.shared.display(header: "Error", message: "Found '\(intTest)' and only integers are allowed.")
                            return
                        }
                    }
                }
            } else {
                _ = Alert.shared.display(header: "Attention", message: "Number of items defined in list of options and number of items defined in the value list must be equal.\n\tCount of options: \(enum_titlesArray.count)\n\tCount of values: \(enumArray.count)")
                return
            }
        }
        let currentKey = TheKey(id: keyId, index: keyIndex, type: keyType, name: keyName_TextField.stringValue, required: (keyRequired_Button.state == .on) ? true:false, friendlyName: keyFriendlyName_TextField.stringValue, desc: keyDescription_TextField.stringValue, infoText: keyInfoText_TextField.stringValue, moreInfo: moreInfo_TextField.stringValue, listType: listType, listHeader: headerOrPlaceholder_TextField.stringValue, listOfOptions: enum_titles_TextView.string, listOfValues: enum_TextView.string)
        delegate?.sendKeyInfo(keyInfo: currentKey)
        dismiss(self)
    }
    
    fileprivate func urlValidation() -> Bool {
        let urlRegex = #"^(http|https)://([\w\.-]+)\.([a-z\.]{2,6})([/\w\.-]*)*/?$"#
        
        if let regex = try? NSRegularExpression(pattern: urlRegex, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: moreInfo_TextField.stringValue.utf16.count)
            if regex.firstMatch(in: moreInfo_TextField.stringValue, options: [], range: range) == nil {
                let response = Alert.shared.display(header: "", message: "The URL for More Info appears invalid", secondButton: "Use Anyway")
                if response != "Use Anyway" {
                    moreInfo_TextField.becomeFirstResponder()
                    return false
                }
            }
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
//        preferredContentSize = CGSize(width: 651, height: 464)
        
//        main_Scrollview.verticalScroller?.isHidden = false
//        main_Scrollview.scrollerStyle = .legacy

        enum_titles_TextView.font = NSFont(name: "Courier", size: 14.0)
        enum_titles_TextView.textColor = isDarkMode ? NSColor.white:NSColor.black
        enum_TextView.font = NSFont(name: "Courier", size: 14.0)
        enum_TextView.textColor = isDarkMode ? NSColor.white:NSColor.black
        
        if existingKey?.name ?? "" != "" {
            whichKeyType = existingKey?.type ?? "Select Key Type"
            let listType = existingKey?.listType ?? ""
            if whichKeyType == "array" {
                whichKeyType = "\(listType) \(whichKeyType)"
            }
            
            keyName_TextField.stringValue = existingKey?.name ?? ""
            keyFriendlyName_TextField.stringValue = existingKey?.friendlyName ?? ""
            keyDescription_TextField.stringValue = existingKey?.desc ?? ""
            keyInfoText_TextField.stringValue = existingKey?.infoText ?? ""
            moreInfo_TextField.stringValue = existingKey?.moreInfo ?? ""
            keyRequired_Button.state = (existingKey?.required ?? false) ? .on:.off
            headerOrPlaceholder_TextField.stringValue = existingKey?.headerOrPlaceholder ?? ""
            enum_titles_TextView.string = existingKey?.listOfOptions ?? ""
            enum_TextView.string = existingKey?.listOfValues ?? ""
            
            add_Button.title = "Update"
        }
    }
    
    override func viewDidAppear() {
        if whichKeyType != "" {
            keyType_Button.selectItem(withTitle: whichKeyType)
            selectKeyType_Action(keyType_Button)
        } else {
            var frame = self.view.window?.frame
            frame?.size = NSSize(width: 651, height: 525)
            self.view.window?.setFrame(frame!, display: true)
//            windowFrameH = view.window?.frame.height ?? 0.0
            scrollAdjust = (keyName_TextField.frame.maxY+34) - main_Scrollview.contentView.bounds.size.height
            main_Scrollview.contentView.scroll(to: NSPoint(x: 1.0, y: scrollAdjust))
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}
