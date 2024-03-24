//
//  ViewController.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa
import CryptoKit
import Foundation

class TheKey: NSObject {
    @objc var id: String
    @objc var index: Int
    @objc var type: String
    @objc var name: String
    @objc var required: Bool
    @objc var friendlyName: String
    @objc var desc: String
    @objc var infoText: String
    @objc var listOfOptions: String
    @objc var listOfValues: String
    
    
    init(id: String, index: Int, type: String, name: String, required: Bool, friendlyName: String, desc: String, infoText: String, listOfOptions: String, listOfValues: String) {
        self.id       = id
        self.index    = index
        self.type     = type
        self.name     = name
        self.required = required
        self.friendlyName = friendlyName
        self.desc = desc
        self.infoText = infoText
        self.listOfOptions = listOfOptions
        self.listOfValues = listOfValues
    }
}

class ViewController: NSViewController, SendingKeyInfoDelegate {
    
    func sendKeyInfo(keyInfo: TheKey) {
        if let existingIndex = currentKeys.firstIndex(where: {$0.id == keyInfo.id}) {
            // update existing key
            currentKeys[existingIndex] = keyInfo
            keys_TableView.reloadData()
            displaySchema()
        } else if let existingIndex = currentKeys.firstIndex(where: {$0.name == keyInfo.name}) {
            Alert.shared.display(header: "", message: "Key name already exists")
            performSegue(withIdentifier: "showKey", sender: keyInfo)
        } else {
            print("[sendKeyInfo] add \(keyInfo.name) to array")
            currentKeys.append(keyInfo)
            keys_TableView.reloadData()
            displaySchema()
        }
    }
    
    let fileManager = FileManager.default
//    @IBOutlet var theKey_AC: NSArrayController!
    
    
//    @IBOutlet weak var keys_TabView: NSTabView!
//    @IBOutlet weak var keyRequired: NSButton!
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    
    
    @IBOutlet weak var keyDescription_TextField: NSTextView!
    @IBOutlet weak var keyInfoText_TextField: NSTextField!
    
    @IBOutlet weak var currentSchema_TextView: NSTextView!
    
//    @IBOutlet weak var keyType_Button: NSPopUpButton!
    
    @IBOutlet weak var import_Button: NSButton!
    @IBOutlet weak var save_Button: NSButton!
    @IBOutlet weak var cancel_Button: NSButton!
    
    @IBOutlet weak var keys_TableView: NSTableView!
    
    @IBAction func copyToClipboard_Action(_ sender: Any) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.setString(currentSchema_TextView.string, forType: .string)
    }
    
//    var preferenceKeys_TableArray: [String]?
    
    // advanced key tab - start
//    @IBOutlet weak var advKeyName_TextField: NSTextField!
//    @IBOutlet weak var advIntegerList_Label: NSTextField!
//    @IBOutlet weak var advIntegerList_TextField: NSTextField!
    
//    @IBOutlet var enum_titles_TextView: NSTextView!
//    @IBOutlet var enum_TextView: NSTextView!
//    @IBOutlet weak var enum_TextField: NSTextField!
    
    let paragraphStyle = NSMutableParagraphStyle()
    var schemaTextAttributes  = [NSAttributedString.Key : Any]()
    var fontColor            = NSColor()
    
    var enum_titlesString = ""
    var enumString        = ""
    var enumValues        = ""   // values written to file for enum
    var readEnumArray     = [Any]()
    // advanced key tab - end
    
    var currentKeys  = [TheKey]()
    var keysArray    = [String]()
    var requiredKeys = [String]()
    
    var valueType = ""
    var keyName   = ""
    
    var   savedHash = ""
    var currentHash = ""
    
//    var keyValuePairs = [String:[String:Any]]()
    
        
    @IBAction func importFile_Action(_ sender: NSButton) {

        if savedHash != currentHash {
            let response = Alert.shared.display(header: "", message: "You have unsaved changes, if you continue the changes will be lost.", secondButton: "Cancel")
            if response == "Cancel" {
                return
            }
        }
        
        var json: Any?
        // filetypes that are selectable
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
                
//                self.keys_TabView.selectTabViewItem(at: 0)
        
                var rawKeyValuePairs = [String: Any]()
                do {
                    preferenceKeys.valuePairs.removeAll()

                    // Getting data from JSON file using the file URL
                    let data = try Data(contentsOf: importPathUrl, options: .mappedIfSafe)
                    json = try? JSONSerialization.jsonObject(with: data)
                    let manifestJson = json as? [String: Any]
//                    print("[import] manifestJson: \(manifestJson ?? [:])")
                    
                    guard let check = manifestJson?["_exported"], "\(check)" == "MASB" else {
                        Alert.shared.display(header: "Error", message: "Unable to parse JSON, verify the format.")
                        return
                    }
                    
                    var existingKey: TheKey?
                    
                    self.preferenceDomain_TextField.stringValue = manifestJson!["title"] as! String
                    self.preferenceDomainDescr_TextField.stringValue = manifestJson!["description"] as! String
                    let properties = manifestJson!["properties"] as! [String: [String: Any]]
                    self.currentKeys.removeAll()
//
                    var propertyOrder = 0
                    var enumTitles = [Any]()
                    var enumList   = [Any]()
                    for (prefKey, keyDetails) in properties {
//                        print("[import] \(prefKey) keyDetails: \(keyDetails)")
                        
//                        existingKey?.name = prefKey
                        let friendlyName = keyDetails["title"] as? String ?? ""
                        let desc = keyDetails["description"] as? String ?? ""
                        let propertyOrder = keyDetails["property_order"] as? Int ?? 0
                        let required = keyDetails["required"] as? Bool ?? false
                        var type = keyDetails["type"] as? String ?? ""
                        let name = keyDetails["title"] as? String ?? ""
                        let options = keyDetails["options"] as? [String: Any] ?? [:]
                        let infoText = options["infoText"] as? String ?? ""
                        if let items = keyDetails["items"] as? [String: Any], let itemsType = items["type"], let itemsTitle = items["title"] as? String {
                            type = "\(type) array"
                        }
                        
                        enumList = keyDetails["enum"] as? [Any] ?? []
                        if enumList.count > 0 {
                            type = ( type == "string" ) ? "string (from list)":"integer (from list)"
                            enumTitles = options["enum_titles"] as? [Any] ?? []
                        } else {
                            
                        }
                        
                        self.currentKeys.append(TheKey(id: UUID().uuidString, index: propertyOrder, type: type, name: name, required: required, friendlyName: friendlyName, desc: desc, infoText: infoText, listOfOptions: enumTitles.arrayToString, listOfValues: enumList.arrayToString))
                        
                        
//                        rawKeyValuePairs = properties[prefKey]!
//
//                        preferenceKeys.valuePairs[prefKey] = [:]
//                        preferenceKeys.valuePairs[prefKey]!["title"] = rawKeyValuePairs["title"] as? String ?? ""
//                        preferenceKeys.valuePairs[prefKey]!["description"] = rawKeyValuePairs["description"] as? String ?? ""
//                        preferenceKeys.valuePairs[prefKey]!["infoText"] = rawKeyValuePairs["infoText"] as? String ?? ""
                        
                        /*
                        let anyOf = rawKeyValuePairs["anyOf"] as! [[String: Any]]
                        if anyOf.count > 1 {
                            let readKeyType = anyOf[1]["type"] as! String
                            preferenceKeys.valuePairs[prefKey]!["valueType"] = readKeyType
                            if readKeyType == "integer" || readKeyType == "string", anyOf[1]["options"] != nil {
                                preferenceKeys.valuePairs[prefKey]!["valueType"] = (anyOf[1]["type"] as! String == "integer") ? "integer (from list)":"array (from list)"
//                                preferenceKeys.valuePairs[prefKey]!["valueType"] = "integer (from list)"
                                // get list of choices
                                let readOptions = anyOf[1]["options"]! as! [String:[String]]
                                var readEnumTitles = "\(String(describing: readOptions["enum_titles"]!))"
                                readEnumTitles = readEnumTitles.replacingOccurrences(of: "[", with: "")
                                readEnumTitles = readEnumTitles.replacingOccurrences(of: "]", with: "")
                                readEnumTitles = readEnumTitles.replacingOccurrences(of: "\"", with: "")
                                preferenceKeys.valuePairs[prefKey]!["enum_titles"] = readEnumTitles
                                
                                // get associated values
                                if readKeyType == "integer" {
                                    self.readEnumArray = anyOf[1]["enum"] as! [Int]
                                } else {
                                    self.readEnumArray = anyOf[1]["enum"] as! [String]
                                }
                                var readEnum = "\(String(describing: self.readEnumArray))"
                                readEnum = readEnum.replacingOccurrences(of: "[", with: "")
                                readEnum = readEnum.replacingOccurrences(of: "]", with: "")
                                readEnum = readEnum.replacingOccurrences(of: "\"", with: "")
                                preferenceKeys.valuePairs[prefKey]!["enum"] = readEnum
                            }
                        } else {
                            preferenceKeys.valuePairs[prefKey]!["valueType"] = "Select Value Type"
                        }
                        */
                    }
                    currentKeys.sort(by: { $0.index < $1.index})
                    keys_TableView.reloadData()
                    displaySchema()
//                    self.keysArray.sort()

//                    if self.keysArray.count > 0 {
//                        preferenceKeys.tableArray = self.keysArray
//                        self.keys_TableView.reloadData()
//                    }
    //                    print("\(json)")
                } catch {
                    print("couldn't reach json file")
                }
            }
        }
    }

    
    @IBAction func addKey_Action(_ sender: Any) {
        if preferenceDomain_TextField.stringValue != "" {
            performSegue(withIdentifier: "showKey", sender: nil)
        } else {
            Alert.shared.display(header: "", message: "A preference domain must first be defined.")
            preferenceDomain_TextField.becomeFirstResponder()
        }
    }
    
    @IBAction func removeKey_Action(_ sender: Any) {
//        DispatchQueue.main.async {
            let theRow = self.keys_TableView.selectedRow
        currentKeys.remove(at: theRow)
//        theKey_AC.remove(atArrangedObjectIndex: theRow)
        displaySchema()
//            if theRow >= 0 {
//                self.keyName = preferenceKeys.tableArray?[theRow] ?? ""
//                preferenceKeys.valuePairs.removeValue(forKey: self.keyName)
//                self.keysArray.remove(at: theRow)
//                preferenceKeys.tableArray = self.keysArray
//
//                self.keys_TableView.reloadData()
//                self.keyName = ""
//                self.keyFriendlyName_TextField.stringValue = ""
//                self.keyDescription_TextField.string = ""
//                self.keyInfoText_TextField.stringValue = ""
//                self.keyType_Button.selectItem(at: 0)
//            }
//        }
    }
    
    func updateKeyValuePair(whichKey: String) {
    
        print("updating friendly name (title) for key \(keyName)")
        preferenceKeys.valuePairs[keyName]!["title"] = "\(keyFriendlyName_TextField.stringValue)"
    
        print("updating description for key \(keyName)")
        preferenceKeys.valuePairs[keyName]!["description"] = "\(keyDescription_TextField.string)"
        
        print("updating info text for key \(keyName)")
        preferenceKeys.valuePairs[keyName]!["infoText"] = "\(keyInfoText_TextField.stringValue)"

//        print("updating data type for key \(keyName) with value \(keyType_Button.titleOfSelectedItem!)")
//        preferenceKeys.valuePairs[keyName]!["valueType"] = "\(keyType_Button.titleOfSelectedItem!)"
        
    }
    
    func displaySchema(reorder: Bool = false) {
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        
        currentSchema_TextView.string = ""
        var keysWritten = 0
        var keyDelimiter = ",\n"
        
        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            currentSchema_TextView.string = "{\n\t\"title\": \"\(preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n"
//
            var requiredKeys = ""
            for theKey in currentKeys {
                if theKey.required {
                    requiredKeys.append("\"\(theKey.name)\",")
                }
//                                print("[displaySchema] key: \(theKey.type), name: \(theKey.name)")
                currentKeys[keysWritten].index = (keysWritten+1)*5
                keysWritten += 1
                if keysWritten == currentKeys.count {
                    keyDelimiter = "\n"
                }
                var keyTypeItems = theKey.type
                switch keyTypeItems {
                case "integer array":
                    keyTypeItems = """
                    "array",
                                "items": {
                                    "type": "integer",
                                    "title": "List of integers"
                                },
                                "options": {
                                    "infoText": "\(theKey.infoText)"
                                }
                    """
                case "string array":
                    keyTypeItems = """
                    "array",
                                "items": {
                                    "type": "string",
                                    "title": "List of strings"
                                },
                                "options": {
                                    "infoText": "\(theKey.infoText)"
                                }
                    """
//
//                                case "base64 encoded string":
//                                    keyTypeItems = "\"data\""
                    
                case "integer (from list)", "string (from list)":
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
                default:
                    keyTypeItems = """
                    "\(keyTypeItems)",
                                "options": {
                                    "infoText": "\(theKey.infoText)"
                                }
                    """
                }
                let text = """
                        "\(theKey.name)": {
                            "title": "\(theKey.friendlyName)",
                            "description": "\(theKey.desc)",
                            "property_order": \(reorder ? keysWritten*5:theKey.index),
                            "type": \(String(describing: keyTypeItems))
                        }\(keyDelimiter)
                """

//                            let text = """
//                                    "\(theKey.name)": {
//                                        "title": "\(theKey.friendlyName)",
//                                        "description": "\(theKey.desc)",
//                                        "property_order": \(keysWritten*5),
//                                        "type": \(String(describing: keyTypeItems))
//                                    }\(keyDelimiter)
//                            """
                currentSchema_TextView.string = currentSchema_TextView.string + text
                
             }   // for (key, _) in packagesDict - end
            if requiredKeys == "" {
                currentSchema_TextView.string = currentSchema_TextView.string + "\t}\n}"
            } else {
                requiredKeys = String(requiredKeys.dropLast())
                currentSchema_TextView.string = currentSchema_TextView.string + "\t},\n\t\"required\": [\(requiredKeys)]\n}"
            }
            let attributedText = NSMutableAttributedString(string: currentSchema_TextView.string, attributes: schemaTextAttributes)
            currentSchema_TextView.textStorage?.setAttributedString(attributedText)
            
            currentHash = currentSchema_TextView.string.hashString
//                            beginSheetModal - end
        } else {
            // preference domain required
            print("preference domain required")
            Alert.shared.display(header: "Attention", message: "You must supply a preference domain.")
            preferenceDomain_TextField.becomeFirstResponder()

        }   // if preferenceDomain_TextField != "" - end
    }
    

    @IBAction func save_Action(_ sender: Any) {

        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            let exportFile = currentSchema_TextView.string.replacingOccurrences(of: "{\n\t\"title\"", with: "{\n\t\"_exported\": \"MASB\",\n\t\"title\"")
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
                        } catch {
                            print("Error writing to file: \(error)")
                        }
                    }
                    savedHash = currentSchema_TextView.string.hashString
                }
            }   // saveDialog.beginSheetModal - end
        } else {
            // preference domain required
            print("preference domain required")
            Alert.shared.display(header: "Attention", message: "You must supply a preference domain.")
            preferenceDomain_TextField.becomeFirstResponder()

        }   // if preferenceDomain_TextField != "" - end
    }   // @IBAction func save_Action - end
   
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "loginView":
           break
        default:
//            print("[prepare] sender: \(String(describing: sender))")
            let keysVC: KeysVC = (segue.destinationController as? KeysVC)!
            keysVC.delegate = self
            if let _ = sender as? TheKey {
                keysVC.existingKey = sender as? TheKey
                keysVC.existingKeyId = (sender as? TheKey)?.id ?? ""
                keysVC.keyIndex = (sender as? TheKey)?.index ?? 0
            } else {
                keysVC.keyIndex = (currentKeys.count+1)*5
            }
        }
    }
    
    
    
    @objc func viewKey() {
        let keyIndex = keys_TableView.clickedRow
        let theKey = currentKeys[keyIndex]
//        let theKey = (theKey_AC.arrangedObjects as! [TheKey])[keyIndex]
        performSegue(withIdentifier: "showKey", sender: theKey)
    }
    
    @objc func newSchema(_ notification: Notification) {
        
        if savedHash != currentHash {
            let response = Alert.shared.display(header: "", message: "You have unsaved changes, if you continue the changes will be lost.", secondButton: "Cancel")
            if response == "Cancel" {
                return
            }
        }
        
        preferenceDomain_TextField.stringValue = ""
        preferenceDomainDescr_TextField.stringValue = ""
        currentKeys.removeAll()
        keys_TableView.reloadData()
        currentSchema_TextView.string = ""
    }
    
    @objc func importSchema(_ notification: Notification) {
        importFile_Action(import_Button)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keys_TableView.delegate = self
        keys_TableView.dataSource = self
        keys_TableView.registerForDraggedTypes([.string])
        
        NotificationCenter.default.addObserver(self, selector: #selector(newSchema(_:)), name: .newSchema, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(importSchema(_:)), name: .importSchema, object: nil)
        
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
        
        keys_TableView.doubleAction = #selector(viewKey)
        
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
    
    @IBAction func quit_Button(_ sender: Any) {
        
        
        NSApplication.shared.terminate(self)
    }
    

}   // class ViewController - end


extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    fileprivate enum CellIdentifiers {
        static let NameCell    = "keyName"
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
//        print("[numberOfRows] \(currentKeys.count)")
        return currentKeys.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        print("[objectValueFor] \(currentKeys[row].name)")
        return "\(currentKeys[row].name)"
    }
    
    
    // dragging rows
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let pasteboard = NSPasteboardItem()
            
        // in this example I'm dragging the row index. Once dropped i'll look up the value that is moving by using this.
        // remember in viewdidload I registered strings so I must set strings to pasteboard
        pasteboard.setString("\(row)", forType: .string)
        return pasteboard
    }
    
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        let canDrop = (row >= 0) // in this example you cannot drop on top two rows
//        print("valid drop \(row)? \(canDrop)")
        if (canDrop) {
            return .move //yes, you can drop on this row
        }
        else {
            return [] // an empty array is the equivalent of nil or 'cannot drop'
        }
    }
    
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pastboard = info.draggingPasteboard
        if let sourceRowString = pastboard.string(forType: .string) {
            let selectionArray = sourceRowString.components(separatedBy: "\n")
//            print("\(selectionArray.count) items selected")
//            print("from \(sourceRowString). dropping row \(row)")
            if ((info.draggingSource as? NSTableView == keys_TableView) && (tableView == keys_TableView)) {
                var objectsMoved = 0
                var indexAdjustment = 0
                for theKey in selectionArray {
                    let value:TheKey = currentKeys[Int(theKey)!-indexAdjustment]
                    
                    currentKeys.remove(at: Int(theKey)! - indexAdjustment)
                    if (row > Int(theKey)!)
                    {
                        currentKeys.insert(value, at: (row - 1 - objectsMoved + objectsMoved))
                        indexAdjustment += 1
                    }
                    else
                    {
                        currentKeys.insert(value, at: (row + objectsMoved))
                    }
                    objectsMoved += 1
                    keys_TableView.reloadData()
                    displaySchema(reorder: true)
                }
                return true
            } else {
                return false
            }
        }
        return false
    }

}

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
    var hashString: String {
        get {
            let digest = SHA256.hash(data: "\(self)".data(using: .utf8) ?? Data())
            let hashValue = digest
                .compactMap { String(format: "%02x", $0) }
                .joined()
            return hashValue
        }
    }
}

extension Notification.Name {
    public static let newSchema = Notification.Name("newSchema")
    public static let importSchema = Notification.Name("importSchema")
}
