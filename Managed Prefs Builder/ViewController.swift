//
//  ViewController.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa
import Foundation

class TheKey: NSObject {
    @objc var type: String
    @objc var name: String
    @objc var required: Bool
    @objc var friendlyName: String
    @objc var desc: String
    @objc var infoText: String
    @objc var listOfOptions: String
    @objc var listOfValues: String
    
    
    init(type: String, name: String, required: Bool, friendlyName: String, desc: String, infoText: String, listOfOptions: String, listOfValues: String) {
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
        if let existingIndex = (theKey_AC.arrangedObjects as! [TheKey]).firstIndex(where: {$0.name == keyInfo.name}) {
            var keyArray = theKey_AC.arrangedObjects as! [TheKey]
            
            
            let theRange = IndexSet(0..<(theKey_AC.arrangedObjects as! [TheKey]).count)
            theKey_AC.remove(atArrangedObjectIndexes: theRange)
            
            keyArray[existingIndex] = keyInfo
            theKey_AC.add(contentsOf: keyArray)
        } else {
            print("[sendKeyInfo] new key name: \(keyInfo.name)")
            theKey_AC.addObject(keyInfo)
        }
        theKey_AC.rearrangeObjects()
        displaySchema()
    }
    
    let fileManager = FileManager.default
    @IBOutlet var theKey_AC: NSArrayController!
    
    
//    @IBOutlet weak var keys_TabView: NSTabView!
//    @IBOutlet weak var keyRequired: NSButton!
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    
    
    @IBOutlet weak var keyDescription_TextField: NSTextView!
    @IBOutlet weak var keyInfoText_TextField: NSTextField!
    
    @IBOutlet weak var currentSchema_TextView: NSTextView!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
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
    var enumString       = ""
    var enumValues       = ""   // values written to file for enum
    var readEnumArray    = [Any]()
    // advanced key tab - end
    
    var keysArray    = [String]()
    var requiredKeys = [String]()
    
    var valueType = ""
    var keyName   = ""
    
//    var keyValuePairs = [String:[String:Any]]()
    
        
    @IBAction func importFile_Button(_ sender: NSButton) {

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
            importDialog.beginSheetModal(for: self.view.window!){ result in
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
                    
                    guard let _ = manifestJson?["title"] else {
                        Alert.shared.display(header: "Error", message: "Unable to parse JSON, verify the format.")
                        return
                    }
                    
                    self.preferenceDomain_TextField.stringValue = manifestJson!["title"] as! String
                    self.preferenceDomainDescr_TextField.stringValue = manifestJson!["description"] as! String
                    let properties = manifestJson!["properties"] as! [String: [String: Any]]
                    self.keysArray.removeAll()
                    preferenceKeys.valuePairs.removeAll()
                    for (prefKey, _) in properties {
                        self.keysArray.append(prefKey)
                        rawKeyValuePairs = properties[prefKey]!

                        preferenceKeys.valuePairs[prefKey] = [:]
                        preferenceKeys.valuePairs[prefKey]!["title"] = rawKeyValuePairs["title"] as? String ?? ""
                        preferenceKeys.valuePairs[prefKey]!["description"] = rawKeyValuePairs["description"] as? String ?? ""
                        preferenceKeys.valuePairs[prefKey]!["infoText"] = rawKeyValuePairs["infoText"] as? String ?? ""
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
                    }
                    self.keysArray.sort()

                    if self.keysArray.count > 0 {
                        preferenceKeys.tableArray = self.keysArray
                        self.keys_TableView.reloadData()
                    }
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
        theKey_AC.remove(atArrangedObjectIndex: theRow)
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

        print("updating data type for key \(keyName) with value \(keyType_Button.titleOfSelectedItem!)")
        preferenceKeys.valuePairs[keyName]!["valueType"] = "\(keyType_Button.titleOfSelectedItem!)"
        
    }
    
    func displaySchema() {
//        if (theKey_AC.arrangedObjects as! [TheKey]).count > 0 {
            
            let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            
            currentSchema_TextView.string = ""
            var keysWritten = 0
            var keyDelimiter = ",\n"
            
            if preferenceDomain_TextField.stringValue != "" {
                var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
                var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
                
//                let saveDialog = NSSavePanel()
//                saveDialog.canCreateDirectories = true
//                saveDialog.nameFieldStringValue = preferenceDomainFile
//                saveDialog.beginSheetModal(for: self.view.window!){ [self] result in
//                    if result == .OK {
//                        preferenceDomainFile = saveDialog.nameFieldStringValue
//                        exportURL            = saveDialog.url!
//                        print("fileName", preferenceDomainFile)

                        currentSchema_TextView.string = "{\n\t\"title\": \"\(preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n"
//                        
                            var requiredKeys = ""
                            for theKey in theKey_AC.arrangedObjects as! [TheKey] {
                                if theKey.required {
                                    requiredKeys.append("\"\(theKey.name)\",")
                                }
                                print("[displaySchema] key: \(theKey.type), name: \(theKey.name)")
//                                preferenceDomainFileOp.seekToEndOfFile()
                                keysWritten += 1
                                if keysWritten == (theKey_AC.arrangedObjects as! [TheKey]).count {
                                    keyDelimiter = "\n"
                                }
                                var keyTypeItems = theKey.type
                                switch keyTypeItems {
                                case "array":
                                    keyTypeItems = """
                                    "array",
                                                "items": {
                                                    "type": "string",
                                                    "title": "Entries"
                                                },
                                                "options": {
                                                    "infoText": "\(theKey.infoText)"
                                                }
                                    """
//                                    
//                                case "base64 encoded string":
//                                    keyTypeItems = "\"data\""
                                    
                                case "integer (from list)", "array (from list)":
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
                                            "property_order": \(keysWritten*5),
                                            "type": \(String(describing: keyTypeItems))
                                        }\(keyDelimiter)
                                """
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
                
//                            beginSheetModal - end
            } else {
                // preference domain required
                print("preference domain required")
                Alert.shared.display(header: "Attention", message: "You must supply a preference domain.")
                preferenceDomain_TextField.becomeFirstResponder()

            }   // if preferenceDomain_TextField != "" - end
//        }
    }
    

    @IBAction func save_Action(_ sender: Any) {

        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            let saveDialog = NSSavePanel()
            saveDialog.canCreateDirectories = true
            saveDialog.nameFieldStringValue = preferenceDomainFile
            saveDialog.beginSheetModal(for: self.view.window!){ [self] result in
                if result == .OK {
                    preferenceDomainFile = saveDialog.nameFieldStringValue
                    exportURL            = saveDialog.url!
                    print("fileName", preferenceDomainFile)
                    if let data = currentSchema_TextView.string.data(using: .utf8) {
                        do {
                            try data.write(to: exportURL)
                            print("Successfully wrote to file!")
                        } catch {
                            print("Error writing to file: \(error)")
                        }
                    }
                    /*
                    if let preferenceDomainFileOp = try? FileHandle(forUpdating: exportURL) {
                         
                        preferenceDomainFileOp.write("\(currentSchema_TextView.string)".data(using: .utf8)!)
                        preferenceDomainFileOp.closeFile()
                        
                        let clipboard = NSPasteboard.general
                        clipboard.clearContents()
                        clipboard.setString(currentSchema_TextView.string, forType: .string)
                        
                    }
                    */
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
            print("[prepare] sender: \(String(describing: sender))")
            let keysVC: KeysVC = (segue.destinationController as? KeysVC)!
            keysVC.delegate = self
            if let _ = sender as? TheKey {
                keysVC.existingKey = sender as? TheKey
            }
        }
    }
    
    @objc func viewKey() {
        let keyIndex = keys_TableView.clickedRow
        let theKey = (theKey_AC.arrangedObjects as! [TheKey])[keyIndex]
        performSegue(withIdentifier: "showKey", sender: theKey)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keys_TableView.delegate = self
//        keys_TableView.dataSource = self
        keys_TableView.registerForDraggedTypes([.string])
        
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
        
        // test record
//        theKey_AC.addObject(TheKey(type: "type", name: "test", required: false, friendlyName: "the name", desc: "", infoText: "", listOfOptions: "", listValues: ""))
//        theKey_AC.rearrangeObjects()
        
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("[numberOfRows] \((theKey_AC.arrangedObjects as! [TheKey]).count)")
        return (theKey_AC.arrangedObjects as! [TheKey]).count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        print("objectValueFor] \((theKey_AC.arrangedObjects as! [TheKey])[row].name)")
        return (theKey_AC.arrangedObjects as! [TheKey])[row].name
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
            print("\(selectionArray.count) items selected")
            print("from \(sourceRowString). dropping row \(row)")
            if ((info.draggingSource as? NSTableView == keys_TableView) && (tableView == keys_TableView)) {
                var objectsMoved = 0
                var indexAdjustment = 0
//                for thePolicy in selectionArray {
//                    let value:Policy = selectedPoliciesArray[Int(thePolicy)!-indexAdjustment]
//                    let theAction:EnrollmentActions = enrollmentActions[Int(thePolicy)!-indexAdjustment]
//                    
//                    selectedPoliciesArray.remove(at: Int(thePolicy)! - indexAdjustment)
//                    enrollmentActions.remove(at: Int(thePolicy)! - indexAdjustment)
//                    if (row > Int(thePolicy)!)
//                    {
//                        selectedPoliciesArray.insert(value, at: (row - 1 - objectsMoved + objectsMoved))
//                        enrollmentActions.insert(theAction, at: (row - 1 - objectsMoved + objectsMoved))
//                        indexAdjustment += 1
//                    }
//                    else
//                    {
//                        selectedPoliciesArray.insert(value, at: (row + objectsMoved))
//                        enrollmentActions.insert(theAction, at: (row + objectsMoved))
//                    }
//                    objectsMoved += 1
//                    selectedPoliciesDict[configuration_Button.titleOfSelectedItem!] = selectedPoliciesArray
//                    keys_TableView.reloadData()
//                }
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    /*
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell_Id"
    }
    
    func tableView(_ object_TableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
    
//        print("[func tableView] item: \(unusedItems_TableArray?[row] ?? nil)")
        guard let item = preferenceKeys.tableArray?[row] else {
            return nil
        }
        
        if tableColumn == object_TableView.tableColumns[0] {
            text = "\(item)"
            cellIdentifier = CellIdentifiers.NameCell
        }
    
        if let cell = object_TableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    
    // crashes if edit is done and change selection with arrow key
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = keys_TableView.selectedRow
        print("row selected: \(selectedRow)")
        let name = keysArray[selectedRow]


        if selectedRow >= 0 && keys_TableView.selectedRowIndexes.count == 1 {
            keyFriendlyName_TextField.stringValue = preferenceKeys.valuePairs[name]!["title"] as! String
            keyDescription_TextField.string = preferenceKeys.valuePairs[name]!["description"] as! String

        }
    }
    */

}
