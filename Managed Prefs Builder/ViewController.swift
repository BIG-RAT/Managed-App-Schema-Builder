//
//  Copyright 2026 Jamf. All rights reserved.
//

import Cocoa
import CryptoKit
import Foundation
import SwiftUI

class TheKey: NSObject {
    @objc var id: String
    @objc var index: Int
    @objc var type: String
    @objc var name: String
    @objc var required: Bool
    @objc var friendlyName: String
    @objc var desc: String
    @objc var defaultValue: String
    @objc var infoText: String
    @objc var moreInfoText: String
    @objc var moreInfoUrl: String
    @objc var listType: String
    @objc var headerOrPlaceholder: String
    @objc var listOfOptions: String
    @objc var listOfValues: String
    
    
    init(id: String, index: Int, type: String, name: String, required: Bool, friendlyName: String, desc: String, defaultValue: String, infoText: String, moreInfoText: String, moreInfoUrl: String, listType: String, listHeader: String, listOfOptions: String, listOfValues: String) {
        self.id       = id
        self.index    = index
        self.type     = type
        self.name     = name
        self.required = required
        self.friendlyName = friendlyName
        self.desc = desc
        self.defaultValue = defaultValue
        self.infoText = infoText
        self.moreInfoText = moreInfoText
        self.moreInfoUrl = moreInfoUrl
        self.listType = listType
        self.headerOrPlaceholder = listHeader
        self.listOfOptions = listOfOptions
        self.listOfValues = listOfValues
    }
}

class ViewController: NSViewController, NSTextFieldDelegate {
    
    let fileManager = FileManager.default

    @IBOutlet weak var appTitle_TextField: NSTextField!
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    
    @IBOutlet weak var currentSchema_TextView: NSTextView!
        
    @IBOutlet weak var import_Button: NSButton!
    
    @IBOutlet weak var save_Button: NSButton!
    @IBOutlet weak var quit_Button: NSButton!
    
    @IBOutlet weak var keys_TableView: NSTableView!
    
    @IBAction func clear_Button(_ sender: Any) {
        let response = Alert.shared.display(header: "", message: "Are you sure you want to remove all keys? This action cannot be undone.", secondButton: "Cancel")
        if response == "Cancel" {
            return
        }
        currentKeys.removeAll()
        keysArray.removeAll()
        requiredKeys.removeAll()
        keys_TableView.reloadData()
        currentSchema_TextView.string = ""
        appTitle_TextField.stringValue = ""
        preferenceDomain_TextField.stringValue = ""
        preferenceDomainDescr_TextField.stringValue = ""
        savedHash = ""
        currentHash = ""
    }
    
    @IBAction func copyToClipboard_Action(_ sender: Any) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.setString(currentSchema_TextView.string, forType: .string)
    }
    
    let paragraphStyle = NSMutableParagraphStyle()
    var schemaTextAttributes  = [NSAttributedString.Key : Any]()
    var fontColor            = NSColor()
    
    var enum_titlesString = ""
    var enumString        = ""
    var enumValues        = ""   // values written to file for enum
    var readEnumArray     = [Any]()
    
    var currentKeys  = [TheKey]()
    var keysArray    = [String]()
    var requiredKeys = [String]()
    
    var valueType = ""
    var keyName   = ""
    
    var   savedHash = ""
    var currentHash = ""
    
    @IBAction func importFile_Action(_ sender: NSButton) {

        if savedHash != currentHash {
            let response = Alert.shared.display(header: "", message: "You have unsaved changes, if you continue the changes will be lost.", secondButton: "Cancel")
            if response == "Cancel" {
                return
            }
        }
        
        var json: Any?
        // filetypes that are selectable
//        let fileTypeArray: Array = ["json", "plist"]
        let fileTypeArray: Array = ["json"]

        var importPathUrl = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    
        let importDialog: NSOpenPanel        = NSOpenPanel()
        importDialog.canChooseDirectories    = false
        importDialog.allowsMultipleSelection = false
        importDialog.resolvesAliases         = true
        importDialog.allowedFileTypes        = fileTypeArray
        importDialog.directoryURL            = importPathUrl
        importDialog.beginSheetModal(for: self.view.window!){ [self] result in
            if result == .OK {
                importPathUrl = importDialog.url!
                
                let fileType = importPathUrl.pathExtension
                   
                do {
                    var manifestJson = [String:Any]()
                    
                    if fileType == "plist" {
                        let data = try Data(contentsOf: importPathUrl)
                        let dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String:Any]
                        let jsonData = try JSONSerialization.data(withJSONObject: dict , options: .prettyPrinted)
                        json = try? JSONSerialization.jsonObject(with: jsonData)
                        manifestJson = json as? [String: Any] ?? [:]
                        
                        print("[importFile_Action] imported JSON: \(manifestJson)")
                    }
                    
                    // Getting data from JSON file using the file URL
                    if fileType == "json" {
                        let data = try Data(contentsOf: importPathUrl, options: .mappedIfSafe)
                        json = try? JSONSerialization.jsonObject(with: data)
                        manifestJson = json as? [String: Any] ?? [:]
                    }
                    //                    print("[import] manifestJson: \(manifestJson ?? [:])")
                    
                    guard let check = manifestJson["_exported"], "\(check)" == "MASB" else {
                        _ = Alert.shared.display(header: "Error", message: "Unable to parse JSON, verify the format.")
                        WriteToLog.shared.message(stringOfText: "Unable to parse JSON, verify the format.")
                        return
                    }
                    if #available(macOS 13.0, *) {
                        WriteToLog.shared.message(stringOfText: "Imported \(importPathUrl.path())")
                    } else {
                        // Fallback on earlier versions
                        WriteToLog.shared.message(stringOfText: "Imported \(importPathUrl.absoluteString)")
                    }
                    
                    //                    var existingKey: TheKey?
                    
                    preferenceDomain_TextField.stringValue = manifestJson["title"] as? String ?? "\(importPathUrl.lastPathComponent.replacingOccurrences(of: ".\(fileType)", with: ""))"
                    appTitle_TextField.stringValue = manifestJson["_appTitle"] as? String ?? preferenceDomain_TextField.stringValue
                    preferenceDomainDescr_TextField.stringValue = manifestJson["description"] as? String ?? ""
                    let properties = manifestJson["properties"] as? [String: [String: Any]] ?? [:]
                    let required   = manifestJson["required"] as? [String] ?? []
                    self.currentKeys.removeAll()
                    //
//                    var propertyOrder = 0
                    
                    for (prefKey, keyDetails) in properties {
//                        print("[import] \(prefKey) keyDetails[default]: \(String(describing: keyDetails["default"]))")
                        var defaultValue = ""
                        var enumTitles = [Any]()
                        var enumList   = [Any]()
                        
                        let friendlyName = keyDetails["title"] as? String ?? ""
                        let desc = keyDetails["description"] as? String ?? ""
                        
                        
                        let propertyOrder = keyDetails["property_order"] as? Int ?? 0
                        let required = ( required.contains(prefKey) ) ? true:false
                        
                        var type = keyDetails["type"] as? String ?? ""
                        var itemsType = ""
                        var headerOrPlaceholder = ""
                        
                        let options = keyDetails["options"] as? [String: Any] ?? [:]
                        let infoText = options["infoText"] as? String ?? ""
                        let inputAttributes = options["inputAttributes"] as? [String: Any] ?? [:]
                        headerOrPlaceholder = "\(inputAttributes["placeholder"] ?? "")"
                        
                        let links = keyDetails["links"] as? [[String: String]] ?? [[:]]
                        var moreInfoText = ""
                        var moreInfo     = ""
                        if let links = keyDetails["links"] as? [[String: String]] {
                            for linkInfo in links {
                                moreInfoText = linkInfo["rel"] ?? ""
                                moreInfo = linkInfo["href"] ?? ""
                            }
                        }
                        
                        if let items = keyDetails["items"] as? [String: Any] {
                            let itemType = items["type"] as? String ?? ""
                            itemsType = "\(itemType)"
                            headerOrPlaceholder = items["title"] as? String ?? ""
                        }
                        
                        switch type {
                        case "boolean":
                            if let _ = keyDetails["default"] as? Bool {
                                defaultValue = "\(keyDetails["default"] as! Bool)"
                            }
                        case "integer":
                            if let _ = keyDetails["default"] as? Int {
                                defaultValue = "\(keyDetails["default"] as! Int)"
                            }
                        case "string", "string (from list)", "integer (from list)":
                            if let _ = keyDetails["default"] as? String {
                                defaultValue = "\(keyDetails["default"] as! String)"
                            }
                        default:
                            defaultValue = ""
                        }
                        
                        enumList = keyDetails["enum"] as? [Any] ?? []
                        if enumList.count > 0 {
                            type = ( type == "string" ) ? "string (from list)":"integer (from list)"
                            itemsType = "\(itemsType) array"
                            enumTitles = options["enum_titles"] as? [Any] ?? []
                        }
                        
                        self.currentKeys.append(TheKey(id: UUID().uuidString, index: propertyOrder, type: type, name: prefKey, required: required, friendlyName: friendlyName, desc: desc, defaultValue: defaultValue, infoText: infoText, moreInfoText: moreInfoText, moreInfoUrl: moreInfo, listType: itemsType, listHeader: headerOrPlaceholder, listOfOptions: enumTitles.arrayToString, listOfValues: enumList.arrayToString))
                    }
                    currentKeys.sort(by: { $0.index < $1.index})
                    keys_TableView.reloadData()
                    displaySchema()
                    savedHash = currentSchema_TextView.string.hashString
                } catch {
                    print("couldn't reach json file")
                }
            }
        }
    }

    @IBAction func addKey_Action(_ sender: Any) {
        if preferenceDomain_TextField.stringValue != "" {
            presentSwiftUIKeysView(existingKey: nil)
        } else {
            _ = Alert.shared.display(header: "", message: "A preference domain must first be defined.")
            preferenceDomain_TextField.becomeFirstResponder()
        }
    }
    
    @IBAction func removeKey_Action(_ sender: Any) {
        let theRow = self.keys_TableView.selectedRow
        currentKeys.remove(at: theRow)
        keys_TableView.reloadData()
        displaySchema()
    }
    
    func displaySchema(reorder: Bool = false) {
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        
        currentSchema_TextView.string = ""
        var keysWritten = 0
        var keyDelimiter = ",\n"
        
        if preferenceDomain_TextField.stringValue != "" {
            let preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
//            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            currentSchema_TextView.string = "{\n\t\"title\": \"\(preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n"
//
            var requiredKeys = ""
            for theKey in currentKeys {
                if theKey.required {
                    requiredKeys.append("\"\(theKey.name)\",")
                }
//                print("[displaySchema] key: \(theKey.type), name: \(theKey.name)")
                
                currentKeys[keysWritten].index = (keysWritten+1)*5
                keysWritten += 1
                if keysWritten == currentKeys.count {
                    keyDelimiter = "\n"
                }
                var keyTypeItems = theKey.type
                var links = ""
                var defaultValue = ""
                var definedDefaultValue = theKey.defaultValue
                
                switch keyTypeItems {
                case "array", "string array", "list array":
                    keyTypeItems = """
                    "array",
                                "items": {
                                    "type": "\(theKey.listType)",
                                    "title": "\(theKey.headerOrPlaceholder)"
                                },
                                "options": {
                                    "infoText": "\(theKey.infoText)"
                                }
                    """
//
//                                case "base64 encoded string":
//                                    keyTypeItems = "\"data\""
                    
                case "integer (from list)", "string (from list)":
                    definedDefaultValue = "\"\(definedDefaultValue)\""
                    let keyTypeItemVar = (keyTypeItems == "integer (from list)") ? "integer":"string"
                    enum_titlesString = ""
//                                enumString        = ""
                    // convert string of enum_titles to array
                    enum_titlesString = (theKey.listOfOptions).replacingOccurrences(of: ", ", with: ",")
                    enum_titlesString = enum_titlesString.replacingOccurrences(of: "\n", with: ",")
                    let enum_titleArray = enum_titlesString.split(separator: ",")
                    
                    // convert string of enum to array
                    enumString = (theKey.listOfValues).replacingOccurrences(of: ", ", with: ",")
                    enumString = enumString.replacingOccurrences(of: "\n", with: ",")
                    if keyTypeItemVar == "string" {
                        let enumValuesArray = enumString.split(separator: ",")
                        enumValues     = "\(enumValuesArray)"
                    } else {
                        enumValues = "[\(enumString)]"
                    }
                    keyTypeItems = """
                    "\(keyTypeItemVar)",
                                "options": {
                                    "enum_titles": \(enum_titleArray),
                                    "infoText": "\(theKey.infoText)"
                                },
                                "enum": \(enumValues)
                    """
                case "string":
                    definedDefaultValue = "\"\(definedDefaultValue)\""
//                    keyTypeItems = "\"string\""
                    fallthrough
                default:
//                    print("[displaySchema] headerOrPlaceholder: \(theKey.headerOrPlaceholder)\n")
                    var placeholder = ""
                    if theKey.headerOrPlaceholder != "" {
                        let placeholderValue = (keyTypeItems == "\"string\"") ? "\(theKey.headerOrPlaceholder)":theKey.headerOrPlaceholder
                        placeholder = """
                        ,
                                        "inputAttributes": {
                                            "placeholder": "\(placeholderValue)"
                                        }
                        """
                    }
                    
                    keyTypeItems = """
                    "\(keyTypeItems)",
                                "options": {
                                    "infoText": "\(theKey.infoText)"\(placeholder)
                                }
                    """
                }
                if theKey.defaultValue != "" {
                    defaultValue = """
                
                            "default": \(definedDefaultValue),
                """
                }
                if theKey.moreInfoUrl != "" {
                    links = """
                ,
                            "links": [
                                {
                                    "rel": "\(theKey.moreInfoText)",
                                    "href": "\(theKey.moreInfoUrl)"
                                }
                            ]
                """
                }
                let text = """
                        "\(theKey.name)": {
                            "title": "\(theKey.friendlyName)",
                            "description": "\(theKey.desc)",\(defaultValue)
                            "property_order": \(reorder ? keysWritten*5:theKey.index),
                            "type": \(String(describing: keyTypeItems))\(links)
                        }\(keyDelimiter)
                """
                currentSchema_TextView.string = currentSchema_TextView.string + text
                
             }
            if requiredKeys == "" {
                currentSchema_TextView.string = currentSchema_TextView.string + "\t}\n}"
            } else {
                requiredKeys = String(requiredKeys.dropLast())
                currentSchema_TextView.string = currentSchema_TextView.string + "\t},\n\t\"required\": [\(requiredKeys)]\n}"
            }
            let attributedText = NSMutableAttributedString(string: currentSchema_TextView.string, attributes: schemaTextAttributes)
            currentSchema_TextView.textStorage?.setAttributedString(attributedText)
            
            currentHash = currentSchema_TextView.string.hashString
        } else {
            // preference domain required
            print("preference domain required")
            _ = Alert.shared.display(header: "Attention", message: "You must supply a preference domain.")
            preferenceDomain_TextField.becomeFirstResponder()

        }
    }
    
    @IBAction func save_Action(_ sender: Any) {

        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            let exportFile = currentSchema_TextView.string.replacingOccurrences(of: "{\n\t\"title\"", with: "{\n\t\"_appTitle\": \"\(appTitle_TextField.stringValue)\",\n\t\"_exported\": \"MASB\",\n\t\"title\"")
            let saveDialog = NSSavePanel()
            saveDialog.canCreateDirectories = true
            saveDialog.nameFieldStringValue = preferenceDomainFile
            saveDialog.beginSheetModal(for: self.view.window!){ [self] result in
                if result == .OK {
                    preferenceDomainFile = saveDialog.nameFieldStringValue
                    exportURL            = saveDialog.url!
                    print("fileName", preferenceDomainFile)
                    if let data = exportFile.data(using: .utf8) {
                        do {
                            try data.write(to: exportURL)
                            print("Successfully wrote to file!")
                            if #available(macOS 13.0, *) {
                                WriteToLog.shared.message(stringOfText: "Successfully wrote to \(exportURL.path())")
                            } else {
                                // Fallback on earlier versions
                                WriteToLog.shared.message(stringOfText: "Successfully wrote to \(exportURL.absoluteString)")
                            }
                        } catch {
                            print("Error writing to file: \(error)")
                            WriteToLog.shared.message(stringOfText: "Error writing to \(exportURL.absoluteString). Error: \(error)")
                        }
                    }
                    savedHash = currentSchema_TextView.string.hashString
                }
            }   // saveDialog.beginSheetModal - end
        } else {
            // preference domain required
            print("preference domain required")
            _ = Alert.shared.display(header: "Attention", message: "You must supply a preference domain.")
            preferenceDomain_TextField.becomeFirstResponder()

        }   // if preferenceDomain_TextField != "" - end
    }   // @IBAction func save_Action - end
   
//    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
//        switch segue.identifier {
//        case "loginView":
//           break
//        default:
////            print("[prepare] sender: \(String(describing: sender))")
//            let keysVC: KeysVC = (segue.destinationController as? KeysVC)!
//            keysVC.delegate = self
//            if let _ = sender as? TheKey {
//                keysVC.existingKey = sender as? TheKey
//                keysVC.existingKeyId = (sender as? TheKey)?.id ?? ""
//                keysVC.keyIndex = (sender as? TheKey)?.index ?? 0
//            } else {
//                keysVC.keyIndex = (currentKeys.count+1)*5
//            }
//        }
//    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        var whichField = ""
        if let textField = obj.object as? NSTextField {
            if currentSchema_TextView.string != "" {
                displaySchema()
            }
            whichField = textField.identifier!.rawValue
            if whichField == "preferenceDomain" && appTitle_TextField.stringValue == "" {
                appTitle_TextField.stringValue = "\(preferenceDomain_TextField.stringValue)"
            }
        } //else {
//            whichField = obj.name.rawValue
//        }
        //
//        print("[controlTextDidEndEditing] obj.name.rawValue: \(obj.name.rawValue)")
//        print("[controlTextDidEndEditing]        whichField: \(whichField)")

    }
    
    @objc func viewKey() {
        let keyIndex = keys_TableView.clickedRow
        let theKey = currentKeys[keyIndex]
        print("[viewKey] default value: \(theKey.defaultValue)")
        performSegue(withIdentifier: "showKey", sender: theKey)
    }
    
    @objc func newSchema(_ notification: Notification) {
        
        if savedHash != currentHash {
            let response = Alert.shared.display(header: "", message: "You have unsaved changes, if you continue the changes will be lost.", secondButton: "Cancel")
            if response == "Cancel" {
                return
            }
        }
        appTitle_TextField.stringValue = ""
        preferenceDomain_TextField.stringValue = ""
        preferenceDomainDescr_TextField.stringValue = ""
        currentKeys.removeAll()
        keys_TableView.reloadData()
        currentSchema_TextView.string = ""
    }
    
    @objc func importSchema(_ notification: Notification) {
        importFile_Action(import_Button)
    }
    
    @objc func quitNow(_ notification: Notification) {
        quit_Action(quit_Button)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //create log file
        Log.file = getCurrentTime().replacingOccurrences(of: ":", with: "") + "_" + Log.file
        if !(FileManager.default.fileExists(atPath: Log.path! + Log.file)) {
            FileManager.default.createFile(atPath: Log.path! + Log.file, contents: nil, attributes: nil)
        }
        didRun = true
        WriteToLog.shared.logCleanup()
        
        WriteToLog.shared.message(stringOfText: "[ViewController] Running Managed App Schema Builder v\(AppInfo.version)")
        
        keys_TableView.delegate = self
        keys_TableView.dataSource = self
        keys_TableView.registerForDraggedTypes([.string])
        
        preferenceDomain_TextField.delegate      = self
        preferenceDomainDescr_TextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(newSchema(_:)), name: .newSchema, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(importSchema(_:)), name: .importSchema, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(quitNow(_:)), name: .quitNow, object: nil)
        
        paragraphStyle.alignment = .left
        keys_TableView.tableColumns.forEach { (column) in
            if column.title == "Key Name \t\t Required" {
                column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 16)])
            } else {
                column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.paragraphStyle: paragraphStyle])
            }
        }
        fontColor = isDarkMode ? NSColor.white:NSColor.black
        schemaTextAttributes = [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: NSFont(name: "Courier", size: 14)!, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        keys_TableView.doubleAction = #selector(viewKey_SwiftUI)
        
    }
    

    override func viewWillAppear() {
        // bring app to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
//        view.wantsLayer = true
//        view.layer?.backgroundColor = CGColor(red: 0x31/255.0, green: 0x4d/255.0, blue: 0x70/255.0, alpha: 1.0)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func quit_Action(_ sender: NSButton) {
        if savedHash != currentHash {
            let response = Alert.shared.display(header: "", message: "You have unsaved changes, if you continue the changes will be lost.", secondButton: "Cancel")
            if response == "Cancel" {
                return
            }
        }
        NSApplication.shared.terminate(self)
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentKeys.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        print("[objectValueFor] \(currentKeys[row].name)")
//        print("Row: \(row), Column: \(tableColumn?.identifier.rawValue ?? "nil")")
//        print("Keys count: \(currentKeys.count)")
//        if row < currentKeys.count {
//            print("Key name: \(currentKeys[row].name)")
//        }
        let keyValues = currentKeys[row]
//        let requiredText = keyValues.required ? " ✓" : ""

        return "\(keyValues.name)"
    }
    
//    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        print("Row: \(row), Column: \(tableColumn?.identifier.rawValue ?? "nil")")
//            print("Keys count: \(currentKeys.count)")
//            if row < currentKeys.count {
//                print("Key name: \(currentKeys[row].name)")
//            }
//        
//        guard row < currentKeys.count else { return nil }
//        let key = currentKeys[row]
//        
//        if tableColumn?.identifier.rawValue == "KeyColumn" {
//            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("KeyCell"), owner: self) as? NSTableCellView
//            
//            // Display both key name and required status
//            let requiredText = key.required ? " ✓" : ""
//            cell?.textField?.stringValue = "\(key.name)\(requiredText)"
//            
//            return cell
//        }
//        
//        if tableColumn?.identifier.rawValue == "TypeColumn" {
//            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("TypeCell"), owner: self) as? NSTableCellView
//            cell?.textField?.stringValue = key.type
//            return cell
//        }
//        
//        return nil
//    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // Handle selection changes if needed
    }
    
    // MARK: - Drag and Drop Support (if you want to restore this functionality)
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let pasteboard = NSPasteboardItem()
        pasteboard.setString("\(row)", forType: .string)
        return pasteboard
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let canDrop = (row >= 0)
        return canDrop ? .move : []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pastboard = info.draggingPasteboard
        guard let sourceRowString = pastboard.string(forType: .string),
              let sourceRow = Int(sourceRowString),
              sourceRow < currentKeys.count else { return false }
        
        if info.draggingSource as? NSTableView == keys_TableView && tableView == keys_TableView {
            let movedKey = currentKeys[sourceRow]
            currentKeys.remove(at: sourceRow)
            
            let insertIndex = sourceRow < row ? row - 1 : row
            currentKeys.insert(movedKey, at: insertIndex)
            
            keys_TableView.reloadData()
            displaySchema(reorder: true)
            return true
        }
        
        return false
    }
}


//extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
//    
//    func numberOfRows(in tableView: NSTableView) -> Int {
//            return currentKeys.count
//        }
//        
//        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?,
//                       row: Int) -> NSView? {
//            guard row < currentKeys.count else { return nil }
//            let key = currentKeys[row]
//            
//            if tableColumn?.identifier.rawValue == "KeyColumn" {
//                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("KeyCell"), owner: self) as? NSTableCellView
//                cell?.textField?.stringValue = key.name
//                return cell
//            }
//            
//            if tableColumn?.identifier.rawValue == "TypeColumn" {
//                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("TypeCell"), owner: self) as? NSTableCellView
//                cell?.textField?.stringValue = key.type
//                return cell
//            }
//            
//            return nil
//        }
//        
//        func tableViewSelectionDidChange(_ notification: Notification) {
//            // Right-click context menu will call viewKey_SwiftUI()
//        }
//    /*
//    fileprivate enum CellIdentifiers {
//        static let NameCell    = "keyName"
//    }
//    
//    func numberOfRows(in tableView: NSTableView) -> Int {
////        print("[numberOfRows] \(currentKeys.count)")
//        return currentKeys.count
//    }
//    
//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
////        print("[objectValueFor] \(currentKeys[row].name)")
//        return "\(currentKeys[row].name)"
//    }
//    
//    
//    // dragging rows
//    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        let pasteboard = NSPasteboardItem()
//            
//        // in this example I'm dragging the row index. Once dropped i'll look up the value that is moving by using this.
//        // remember in viewdidload I registered strings so I must set strings to pasteboard
//        pasteboard.setString("\(row)", forType: .string)
//        return pasteboard
//    }
//    
//    
//    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
//        
//        let canDrop = (row >= 0) // in this example you cannot drop on top two rows
////        print("valid drop \(row)? \(canDrop)")
//        if (canDrop) {
//            return .move //yes, you can drop on this row
//        }
//        else {
//            return [] // an empty array is the equivalent of nil or 'cannot drop'
//        }
//    }
//    
//    
//    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
//        let pastboard = info.draggingPasteboard
//        if let sourceRowString = pastboard.string(forType: .string) {
//            let selectionArray = sourceRowString.components(separatedBy: "\n")
////            print("\(selectionArray.count) items selected")
////            print("from \(sourceRowString). dropping row \(row)")
//            if ((info.draggingSource as? NSTableView == keys_TableView) && (tableView == keys_TableView)) {
//                var objectsMoved = 0
//                var indexAdjustment = 0
//                for theKey in selectionArray {
//                    let value:TheKey = currentKeys[Int(theKey)!-indexAdjustment]
//                    
//                    currentKeys.remove(at: Int(theKey)! - indexAdjustment)
//                    if (row > Int(theKey)!)
//                    {
//                        currentKeys.insert(value, at: (row - 1 - objectsMoved + objectsMoved))
//                        indexAdjustment += 1
//                    }
//                    else
//                    {
//                        currentKeys.insert(value, at: (row + objectsMoved))
//                    }
//                    objectsMoved += 1
//                    keys_TableView.reloadData()
//                    displaySchema(reorder: true)
//                }
//                return true
//            } else {
//                return false
//            }
//        }
//        return false
//    }
//    */
//
//}

extension [Any] {
    var arrayToString: String {
        get {
            var newString = ""
            if self.count > 0 {
                for i in 0..<self.count-1 {
                    newString.append("\(self[i]), ")
                }
                newString.append("\(self.last ?? "-unknown-")")
            }
            return newString
        }
    }
}

extension String {
    var fqdnFromUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "/")
            if nameArray.count > 2 {
                fqdn = nameArray[2]
            } else {
                fqdn =  self
            }
            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            return fqdn
        }
    }
    var hashString: String {
        get {
            let digest = SHA256.hash(data: "\(self)".data(using: .utf8) ?? Data())
            let hashValue = digest
                .compactMap { String(format: "%02x", $0) }
                .joined()
            return hashValue
        }
    }
    var trimTrailingSlash: String {
        get {
            var newString = self
                
            while newString.last == "/" {
                newString = "\(newString.dropLast(1))"
            }
            return newString
        }
    }
}

extension Notification.Name {
    public static let newSchema = Notification.Name("newSchema")
    public static let importSchema = Notification.Name("importSchema")
    public static let quitNow = Notification.Name("quitNow")
}

extension ViewController {
    
    // Updated viewKey method to use SwiftUI
    @objc func viewKey_SwiftUI() {
        let keyIndex = keys_TableView.clickedRow
        guard keyIndex >= 0 && keyIndex < currentKeys.count else { return }
        let theKey = currentKeys[keyIndex]
        presentSwiftUIKeysView(existingKey: theKey)
    }
    
    // Method to present SwiftUI view as a sheet
    func presentSwiftUIKeysView(existingKey: TheKey?) {
        let index = existingKey != nil
            ? currentKeys.firstIndex { $0.id == existingKey!.id } ?? 0
            : currentKeys.count
        
        let hostingController = NSHostingController(
            rootView: KeysView(
                existingKey: existingKey,
                keyIndex: index,
                onSave: { [weak self] newKey in
                    self?.handleKeyInfo(keyInfo: newKey)
                },
                onDismiss: { [weak self] in
                    // Use dismissSheet instead of dismiss(nil)
                    self?.dismissSheet()
                }
            )
        )
        
        hostingController.view.frame.size = NSSize(width: 650, height: 700)
        presentAsSheet(hostingController)
    }
    
    // Helper method to properly dismiss sheet
    private func dismissSheet() {
        if let sheet = self.presentedViewControllers?.first {
            self.dismiss(sheet)
        }
    }
    
    // Handle the key info returned from SwiftUI view
    private func handleKeyInfo(keyInfo: TheKey) {
        if let existingIndex = currentKeys.firstIndex(where: {$0.id == keyInfo.id}) {
            // update existing key
            currentKeys[existingIndex] = keyInfo
            keys_TableView.reloadData()
            displaySchema()
        } else if let _ = currentKeys.firstIndex(where: {$0.name == keyInfo.name}) {
            _ = Alert.shared.display(header: "", message: "Key name already exists")
            presentSwiftUIKeysView(existingKey: keyInfo)
        } else {
            print("[handleKeyInfo] add \(keyInfo.name) to array")
            currentKeys.append(keyInfo)
            keys_TableView.reloadData()
            displaySchema()
        }
    }
}
