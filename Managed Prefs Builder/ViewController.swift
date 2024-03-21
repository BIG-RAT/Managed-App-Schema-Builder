//
//  ViewController.swift
//  Managed App Schema Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController {
    
    let fileManager = FileManager.default
    
    let userDefaults = UserDefaults.standard
    // determine if we're using dark mode
    var isDarkMode: Bool {
        let mode = userDefaults.string(forKey: "AppleInterfaceStyle")
        return mode == "Dark"
    }
    
    @IBOutlet weak var keys_TabView: NSTabView!
    @IBOutlet weak var keyRequired: NSButton!
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    
    
    @IBOutlet weak var keyDescription_TextField: NSTextView!
    @IBOutlet weak var keyInfoText_TextField: NSTextField!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
    @IBOutlet weak var save_Button: NSButton!
    @IBOutlet weak var cancel_Button: NSButton!
    
    @IBOutlet weak var keys_TableView: NSTableView!
//    var preferenceKeys_TableArray: [String]?
    
    // advanced key tab - start
    @IBOutlet weak var advKeyName_TextField: NSTextField!
    @IBOutlet weak var advIntegerList_Label: NSTextField!
//    @IBOutlet weak var advIntegerList_TextField: NSTextField!
    
    @IBOutlet var enum_titles_TextView: NSTextView!
    @IBOutlet var enum_TextView: NSTextView!
    @IBOutlet weak var enum_TextField: NSTextField!
    
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
                
                self.keys_TabView.selectTabViewItem(at: 0)
        
                var rawKeyValuePairs = [String: Any]()
                do {
                    preferenceKeys.valuePairs.removeAll()

                    // Getting data from JSON file using the file URL
                    let data = try Data(contentsOf: importPathUrl, options: .mappedIfSafe)
                    json = try? JSONSerialization.jsonObject(with: data)
                    let manifestJson = json as? [String: Any]
                    
                    guard let _ = manifestJson?["title"] else {
                        Alert().display(header: "Error", message: "Unable to parse JSON, verify the format.")
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
        
        let currentTab = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"
        
        if currentTab == "valueTypeDefs" {
            Alert().display(header: "Attention", message: "Click 'OK' or 'Cancel' before adding a new key.")
            return
        }
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        DispatchQueue.main.async {
            
            let dialog: NSAlert = NSAlert()
            dialog.messageText = "Add new preference key:"
            dialog.alertStyle = NSAlert.Style.informational

            let newKey = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            newKey.stringValue = ""

            dialog.addButton(withTitle: "Add")
            dialog.addButton(withTitle: "Cancel")
            
            dialog.accessoryView = newKey
            dialog.beginSheetModal(for: self.view.window!){ [self] result in
                if result == NSApplication.ModalResponse.alertFirstButtonReturn {

                    print("keyName: \(newKey.stringValue)")
                    if newKey.stringValue != "" {
                        keyName = newKey.stringValue
                        // see if key already exists - start
                        if let _ = keysArray.firstIndex(of: keyName) {
                            Alert().display(header: "Attention", message: "Key already exists.")
                            keyName = ""
                            return
                        } else {
                            print("new key")
                            keysArray.append(keyName)
                            keysArray.sort()
                            preferenceKeys.tableArray = keysArray
                            
                            keys_TableView.reloadData()
                            preferenceKeys.valuePairs[keyName] = [:]
                            // initialize values - start
                            preferenceKeys.valuePairs[keyName]!["title"] = keyName
                            keyFriendlyName_TextField.stringValue = keyName
                            preferenceKeys.valuePairs[keyName]!["required"] = false
                            keyRequired.state = .off
                            preferenceKeys.valuePairs[keyName]!["description"] = ""
                            keyDescription_TextField.string = ""
                            preferenceKeys.valuePairs[keyName]!["infoText"] = ""
                            keyInfoText_TextField.stringValue = ""
                            preferenceKeys.valuePairs[keyName]!["enum_titles"] = ""
                            enum_titles_TextView.string = ""
                            preferenceKeys.valuePairs[keyName]!["enum"] = ""
                            enum_TextView.string = ""
                            keyType_Button.selectItem(at: 0)
                            preferenceKeys.valuePairs[keyName]!["valueType"] = "Select Value Type"
                            let keyIndex = preferenceKeys.tableArray?.firstIndex(of: keyName)
                            keys_TableView.selectRowIndexes(.init(integer: keyIndex!), byExtendingSelection: false)
                            // initialize values - end
                        }
                        // see if key already exists - end
                    }
                } else {
                    print("cancelled add key")
                }
            } // added with modal
            
//            Add to edit existing key name?
//            self.keys_TableView.editColumn(0, row: theRow, with: nil, select: true)
            

        }
    }
    
    @IBAction func removeKey_Action(_ sender: Any) {
        DispatchQueue.main.async {
            let theRow = self.keys_TableView.selectedRow
            if theRow >= 0 {
                self.keyName = preferenceKeys.tableArray?[theRow] ?? ""
                preferenceKeys.valuePairs.removeValue(forKey: self.keyName)
                self.keysArray.remove(at: theRow)
                preferenceKeys.tableArray = self.keysArray

                self.keys_TableView.reloadData()
                self.keyName = ""
                self.keyFriendlyName_TextField.stringValue = ""
                self.keyDescription_TextField.string = ""
                self.keyInfoText_TextField.stringValue = ""
                self.keyType_Button.selectItem(at: 0)
            }
        }
    }
    
    @IBAction func selectKeyName(_ sender: Any) {

//        print("[updateView] selected row: \(rowSelected)")
        let currentTab = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"

        if keyName != "" && currentTab == "main" {
            updateKeyValuePair(whichKey: keyName)
        } else {
            keys_TabView.selectTabViewItem(at: 0)
            save_Button.isHidden = false
            cancel_Button.isHidden = false
        }
        
        let rowSelected = keys_TableView.selectedRow
                if rowSelected >= 0 {
                    keyName = preferenceKeys.tableArray?[rowSelected] ?? ""
                } else {
                    keyName = ""
                }
                
                if keyName != "" {
                    if let _ = preferenceKeys.valuePairs[keyName]!["title"] {
        //                keyTitle = try! preferenceKeys.valuePairs[keyName]!["title"] as! String
                        keyFriendlyName_TextField.stringValue = preferenceKeys.valuePairs[keyName]!["title"] as! String
                    } else {
                        keyFriendlyName_TextField.stringValue = ""
                    }

                    if let _ = preferenceKeys.valuePairs[keyName]!["description"] {
                        keyDescription_TextField.string = preferenceKeys.valuePairs[keyName]!["description"] as! String
                    } else {
                        keyDescription_TextField.string = ""
                    }
                    
                    if let _ = preferenceKeys.valuePairs[keyName]!["infoText"] {
                        keyInfoText_TextField.stringValue = preferenceKeys.valuePairs[keyName]!["infoText"] as! String
                    } else {
                        keyInfoText_TextField.stringValue = ""
                    }

                    if preferenceKeys.valuePairs[keyName]!["valueType"] as! String != "Select Value Type" {
                        keyType_Button.selectItem(withTitle: "\(String(describing: preferenceKeys.valuePairs[keyName]!["valueType"]!))")
                    }
                    
                    if (preferenceKeys.valuePairs[keyName]!["enum_titles"] != nil) {
                        enum_titles_TextView.string = preferenceKeys.valuePairs[keyName]!["enum_titles"]! as! String
                    } else {
                        enum_titles_TextView.string = ""
                    }
                    
                    if (preferenceKeys.valuePairs[keyName]!["enum"] != nil) {
                        enum_TextView.string = preferenceKeys.valuePairs[keyName]!["enum"]! as! String
                    } else {
                        enum_TextView.string = ""
                    }
                }   // if keyName != ""
                
    }
    
    @IBAction func requireKey_Action(_ sender: NSButton) {
//        if sender.state == .on && requiredKeys.firstIndex(of: <#T##String#>)
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
        
        if "\(keyType_Button.titleOfSelectedItem!)" == "integer (from list)" || "\(keyType_Button.titleOfSelectedItem!)" == "array (from list)"{
//            enum_titlesString = ""
//            enumString        = ""
//            enum_titlesString = enum_titles_TextView.string.replacingOccurrences(of: ", ", with: ",")
//            let enum_titleArray = enum_titlesString.split(separator: ",")
//            enum_titlesString = "\(enum_titleArray)"
            print("updating enum_title for key \(keyName)")
            preferenceKeys.valuePairs[keyName]!["enum_titles"] = "\(enum_titles_TextView.string)".replacingOccurrences(of: "\"", with: "")
            
            enumString = enum_TextView.string
            print("updating enum for key \(keyName)")
//            preferenceKeys.valuePairs[keyName]!["enum"] = "[\(enumString)]"
            preferenceKeys.valuePairs[keyName]!["enum"] = "\(enum_TextView.string)".replacingOccurrences(of: "\"", with: "")
        }
    }

    @IBAction func save_Action(_ sender: Any) {
                
//                let timeStamp = Time().getCurrent()
        tab.current = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"
        
        if tab.current == "valueTypeDefs" {
            Alert().display(header: "Attention", message: "Click 'OK' or 'Cancel' before saving.")
            return
        }
        
        if keyName != "" {
            print("[save_Action] keyName: \(keyName)")
            updateKeyValuePair(whichKey: keyName)
        }
        
        var keysWritten = 0
        var keyDelimiter = ",\n"
        
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            let saveDialog = NSSavePanel()
            saveDialog.canCreateDirectories = true
            saveDialog.nameFieldStringValue = preferenceDomainFile
            saveDialog.beginSheetModal(for: self.view.window!){ result in
                if result == .OK {
                    preferenceDomainFile = saveDialog.nameFieldStringValue
                    exportURL            = saveDialog.url!
                    print("fileName", preferenceDomainFile)

                    do {
                        try "{\n\t\"title\": \"\(self.preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(self.preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n".write(to: exportURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("failed to write the.")
                    }
                    
                    if let preferenceDomainFileOp = try? FileHandle(forUpdating: exportURL) {
                         for (key, _) in preferenceKeys.valuePairs {
                            preferenceDomainFileOp.seekToEndOfFile()
                            keysWritten += 1
                            if keysWritten == preferenceKeys.valuePairs.count {
                                keyDelimiter = "\n"
                            }
        //                                     let text = "\t{\"id\": \"\(String(describing: preferenceKeys.valuePairs[key]!["id"]!))\", \"name\": \"\(key)\"},\n"
                            var keyTypeItems = "\(String(describing: preferenceKeys.valuePairs[key]!["valueType"]!))"
                            switch keyTypeItems {
                            case "array":
                                keyTypeItems = """
                                "array",
                                                    "items": {
                                                        "type": "string",
                                                        "title": "Entries"
                                                    }
                                """
                                
                            case "base64 encoded string":
                                keyTypeItems = "\"data\""
                                
                            case "integer (from list)", "array (from list)":
                                let keyTypeItemVar = (keyTypeItems == "integer (from list)") ? "integer":"string"
                                self.enum_titlesString = ""
//                                self.enumString        = ""
                                // convert string of enum_titles to array
                                self.enum_titlesString = (preferenceKeys.valuePairs[key]!["enum_titles"]! as! String).replacingOccurrences(of: ", ", with: ",")
                                self.enum_titlesString = self.enum_titlesString.replacingOccurrences(of: "\n", with: ",")
                                let enum_titleArray = self.enum_titlesString.split(separator: ",")
                                
                                // convert string of enum to array
                                self.enumString = (preferenceKeys.valuePairs[key]!["enum"]! as! String).replacingOccurrences(of: ", ", with: ",")
                                self.enumString = self.enumString.replacingOccurrences(of: "\n", with: ",")
                                if keyTypeItemVar == "string" {
                                    let enumValuesArray = self.enumString.split(separator: ",")
                                    self.enumValues     = "\(enumValuesArray)"
                                } else {
                                    self.enumValues = "[\(self.enumString)]"
                                }
                                keyTypeItems = """
                                "\(keyTypeItemVar)",
                                                    "options": {
                                                        "enum_titles": \(enum_titleArray)
                                                    },
                                                    "enum": \(self.enumValues)
                                """
                            default:
                                keyTypeItems = """
                                "\(keyTypeItems)"
                                """
                            }
                            let text = """
                                    "\(key)": {
                                        "title": "\(String(describing: preferenceKeys.valuePairs[key]!["title"]!))",
                                        "description": "\(String(describing: preferenceKeys.valuePairs[key]!["description"]!))",
                                        "property_order": \(keysWritten*5),
                                        "type": \(String(describing: keyTypeItems))
                                        "options": {
                                            "infoText": "\(String(describing: preferenceKeys.valuePairs[key]!["infoText"]!))"
                                        }
                                    }\(keyDelimiter)
                            """
                            preferenceDomainFileOp.write(text.data(using: String.Encoding.utf8)!)
                            
                         }   // for (key, _) in packagesDict - end
                        preferenceDomainFileOp.seekToEndOfFile()
                        preferenceDomainFileOp.write("\t}\n}".data(using: String.Encoding.utf8)!)
                        preferenceDomainFileOp.closeFile()
                        
                        do {
                            let manifest = try String(contentsOf: exportURL)
        //                    print("manifest: \(manifest)")
                            // copy manifest to clipboard - start
                            let clipboard = NSPasteboard.general
                            clipboard.clearContents()
                            clipboard.setString(manifest, forType: .string)
                            // copy manifest to clipboard - end
                        } catch {
                            print("file not found.")
                        }
                        
                    }
                }
            }   // saveDialog.beginSheetModal - end
        } else {
            // preference domain required
            print("preference domain required")
            Alert().display(header: "Attention", message: "You must supply a preference domain.")
            preferenceDomain_TextField.becomeFirstResponder()

        }   // if preferenceDomain_TextField != "" - end
    }   // @IBAction func save_Action - end
    
    // valueType actions - start
    @IBAction func showAdvKeyTab(_ sender: Any) {
        cancel_Button.isHidden = true
        save_Button.isHidden = true
        let advKeyType = keyType_Button.titleOfSelectedItem!
        advKeyName_TextField.stringValue = "Key Type: \(String(describing: advKeyType))"
        
        tab.current = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"
//        if advKeyType == "array" {
//            advIntegerList_Label.isHidden     = true
//            advIntegerList_TextField.isHidden = true
//        } else {
//            advIntegerList_Label.isHidden     = false
//            advIntegerList_TextField.isHidden = false
//        }
        self.keys_TabView.selectTabViewItem(at: 1)
    }
    
    @IBAction func showMainKeyTab(_ sender: NSButton) {
        if sender.title == "Cancel" {
            self.keys_TabView.selectTabViewItem(at: 0)
            cancel_Button.isHidden = false
            save_Button.isHidden = false
            if let _ = preferenceKeys.valuePairs[keyName]?["enum_titles"] {
                enum_titles_TextView.string = preferenceKeys.valuePairs[keyName]!["enum_titles"] as! String
            } else {
                enum_titles_TextView.string = ""
            }
            if let _ = preferenceKeys.valuePairs[keyName]?["enum"] {
                enum_TextView.string  = preferenceKeys.valuePairs[keyName]!["enum"] as! String
            } else {
                enum_TextView.string = ""
            }
            tab.current = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"
            return
        }
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
                        Alert().display(header: "Error", message: "Found '\(intTest)' and only integers are allowed.")
                        return
                    }
                }
            }

            
            self.keys_TabView.selectTabViewItem(at: 0)
            cancel_Button.isHidden = false
            save_Button.isHidden = false
            tab.current = "\(String(describing: keys_TabView.selectedTabViewItem!.label))"
        } else {
            Alert().display(header: "Attention", message: "Number of items defined in list of options and number of items defined in the value list must be equal.\n\tCount of options: \(enum_titlesArray.count)\n\tCount of values: \(enumArray.count)")
        }
    }
    // valueType actions - end

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keys_TableView.delegate   = self
        keys_TableView.dataSource = self
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        keys_TableView.tableColumns.forEach { (column) in
            if column.title == "Key Name \t\t Required" {
                column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 16)])
            } else {
                column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.paragraphStyle: paragraphStyle])
            }
        }
        
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


extension ViewController: NSTableViewDataSource {

  func numberOfRows(in keys_TableView: NSTableView) -> Int {
    return preferenceKeys.tableArray?.count ?? 0
  }
}

extension ViewController: NSTableViewDelegate {

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
//    func tableViewSelectionDidChange(_ notification: Notification) {
//        let selectedRow = keys_TableView.selectedRow
//        print("row selected: \(selectedRow)")
//        let name = keysArray[selectedRow]
//
//
//        if selectedRow >= 0 && keys_TableView.selectedRowIndexes.count == 1 {
//            keyFriendlyName_TextField.stringValue = preferenceKeys.valuePairs[name]!["title"] as! String
//            keyDescription_TextField.string = preferenceKeys.valuePairs[name]!["description"] as! String
//
//        }
//    }

}
