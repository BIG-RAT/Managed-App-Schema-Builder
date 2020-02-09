//
//  ViewController.swift
//  Managed Prefs Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    @IBOutlet weak var keyDescription_TextField: NSTextView!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
    
    @IBOutlet weak var keys_TableView: NSTableView!
    var preferenceKeys_TableArray: [String]?
    
    var keysArray = [String]()
    
    var valueType = ""
    var keyName   = ""
    
    var keyValuePairs = [String:[String:Any]]()
    
        
//        @IBAction func selectFile_Button(_ sender: NSButton) {
//
//            let path = selectFile()
////            var lines = [String]()
//            var json: Any?
////            summary_TextField.font = NSFont.init(name: "Monaco", size: 10.0)
//
////            self.summary_TextField.string = ""
//
//            if (path != "") {
//                //    var err = NSError?()
//                print("path: \(path)")
//                do {
//                    let fileUrl = URL(fileURLWithPath: path)
//                    // Getting data from JSON file using the file URL
//                    let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
//                    json = try? JSONSerialization.jsonObject(with: data)
//                    let manifestJson = json as? [String: Any]
////                    for (key, _) in manifestJson! {
////                        print("key: \(key)")
////                    }
//                    let properties = manifestJson!["properties"] as! [String:Any]
//                    keysArray.removeAll()
//                    for (domain, _) in properties {
//                        print("domain: \(domain)")
////                        keys_Button.addItem(withTitle: domain)
//                        keysArray.append(domain)
//                        keysDict[domain] = properties[domain] as? [String : Any]
////                        description_TextView.string = keysDict[domain]!["description"] as! String
//                    }
//                    keysArray.sort()
//                    keys_Button.addItems(withTitles: keysArray)
//                    if keysArray.count > 0 {
//                        preferenceKeys_TableArray = keysArray
//                        keys_TableView.reloadData()
//                    }
////                    print("\(json)")
//                } catch {
//                    print("couldn't reach json file")
//                }
//
//                do {
//                    let text = try String(contentsOfFile: path)
//                    //let text = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &err)
//
//                    if (text != "") {
////                        lines = text.components(separatedBy: "\n")
//
//    //                    for line in lines {
//    //                        print(line)
//    //                    }
//                        DispatchQueue.main.async {
////                            let trimmedSummary = ParseSummary().parse(fileArray: lines)
////                            for summaryLine in trimmedSummary {
////                                self.summary_TextField.string = self.summary_TextField.string + summaryLine
////                            }
//
//                        }
//                    } else {
//                        print("cancelled")
//                    }
//                } catch {
//                    print("unable to read file")
////                    self.summary_TextField.string = "Unable to read file."
////                    self.summary_TextField.string = "Try to resave the summary with a plain text editor."
//                }
//            }
//
//        }
    
    
    @IBAction func addKey_Action(_ sender: Any) {
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        DispatchQueue.main.async {
            
            let dialog: NSAlert = NSAlert()
            dialog.messageText = "Add new preference key"
            dialog.informativeText = "New key name"
            dialog.alertStyle = NSAlert.Style.warning

            let newKey = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            newKey.stringValue = ""

            dialog.addButton(withTitle: "Add")
            dialog.addButton(withTitle: "Cancel")
            
            dialog.accessoryView = newKey
            let response: NSApplication.ModalResponse = dialog.runModal()
            
            print("keyName: \(newKey.stringValue)")

            if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
//                self.preferenceKeys_TableArray?.append(newKey.stringValue)
                self.keyName = newKey.stringValue
                self.keysArray.append(self.keyName)
                self.keysArray.sort()
                self.preferenceKeys_TableArray = self.keysArray
                self.keys_TableView.reloadData()
                self.keyValuePairs[self.keyName] = [:]
                // initialize values - start
                self.keyValuePairs[self.keyName]!["title"] = self.keyName
                self.keyFriendlyName_TextField.stringValue = self.keyName
                self.keyValuePairs[self.keyName]!["description"] = ""
                self.keyDescription_TextField.string = ""
                self.keyType_Button.selectItem(at: 0)
                self.keyValuePairs[self.keyName]!["valueType"] = "Select Value Type"
                // initialize values - end
            }
            
            
//            Add to edit existing key name?
//            self.keys_TableView.editColumn(0, row: theRow, with: nil, select: true)
            

        }
    }
    
    @IBAction func selectKeyName(_ sender: Any) {
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        let theRow = keys_TableView.selectedRow
        if theRow >= 0 {
            keyName = preferenceKeys_TableArray?[theRow] ?? ""
        } else {
            keyName = ""
        }
        
        if keyName != "" {
            if let _ = keyValuePairs[keyName]!["title"] {
//                keyTitle = try! keyValuePairs[keyName]!["title"] as! String
                keyFriendlyName_TextField.stringValue = keyValuePairs[keyName]!["title"] as! String
            } else {
                keyFriendlyName_TextField.stringValue = ""
            }

            if let _ = keyValuePairs[keyName]!["description"] {
                keyDescription_TextField.string = keyValuePairs[keyName]!["description"] as! String
            } else {
                keyDescription_TextField.string = ""
            }

            if keyValuePairs[keyName]!["valueType"] as! String != "Select Value Type" {
                keyType_Button.selectItem(withTitle: "\(String(describing: keyValuePairs[keyName]!["valueType"]!))")
            }
        }   // if keyName != ""
        
    }
    
    
    func updateKeyValuePair(whichKey: String) {
    
        print("updating friendly name (title) for key \(keyName)")
        keyValuePairs[keyName]!["title"] = "\(keyFriendlyName_TextField.stringValue)"
    
        print("updating description for key \(keyName)")
        keyValuePairs[keyName]!["description"] = "\(keyDescription_TextField.string)"

        print("updating data type for key \(keyName) with value \(keyType_Button.titleOfSelectedItem!)")
        keyValuePairs[keyName]!["valueType"] = "\(keyType_Button.titleOfSelectedItem!)"
    }
    
    func selectFile() -> String  {
        
        let fileTypeArray: Array = ["json"]
        
        let defaultPath: String = NSHomeDirectory() + "/Desktop"
        //let defaultPath: String = "/Users"
        //let pathURL = NSURL(fileURLWithPath: defaultPath.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!, isDirectory: true)
        let pathURL = NSURL(fileURLWithPath: defaultPath, isDirectory: false)
        
            let myFileDialog: NSOpenPanel        = NSOpenPanel()
            myFileDialog.canChooseDirectories    = false
            myFileDialog.allowsMultipleSelection = false
            myFileDialog.resolvesAliases         = true
            myFileDialog.allowedFileTypes        = fileTypeArray
            myFileDialog.directoryURL            = pathURL as URL
            
            myFileDialog.runModal()
            
            // Get the path to the file chosen in the NSOpenPanel
            let filePath = myFileDialog.url?.path
            
            // Make sure that a path was chosen
            if (filePath != nil) {
                return filePath!
                //        var err = NSError?()
                //        do {
                //            //let dataFile = try String(contentsOfFile: filePath!)
                //            return filePath!
                //        } catch {
                //            print("cancelled")
                //            // something
                //        }
                //let text = String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding, error: &err)
            }
            //return selectedFile
            return ""
    }   // func selectFile() -> String - end

    @IBAction func save_Action(_ sender: Any) {
                
//                let timeStamp = Time().getCurrent()
        var keysWritten = 0
        var keyDelimiter = ",\n"
        
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
                        let preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
        //                let preferenceDomainFile = "prunePackages_\(timeStamp).xml"
                        let exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)

                        do {
                            try "{\n\t\"title\": \"\(preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n".write(to: exportURL, atomically: true, encoding: .utf8)
                        } catch {
                            print("failed to write the.")
                        }
                        
                        if let preferenceDomainFileOp = try? FileHandle(forUpdating: exportURL) {
                             for (key, _) in keyValuePairs {
                                preferenceDomainFileOp.seekToEndOfFile()
                                keysWritten += 1
                                if keysWritten == keyValuePairs.count {
                                    keyDelimiter = "\n"
                                }
//                                     let text = "\t{\"id\": \"\(String(describing: keyValuePairs[key]!["id"]!))\", \"name\": \"\(key)\"},\n"
                                let text = """
                                \t\t"\(key)": {
                                \t\t\t"title": "\(String(describing: keyValuePairs[key]!["title"]!))",
                                \t\t\t"description": "\(String(describing: keyValuePairs[key]!["description"]!))",
                                \t\t\t"property_order": \(keysWritten),
                                \t\t\t"anyOf": [
                                \t\t\t\t{"type": "null", "title": "Not Configured"},
                                \t\t\t\t{
                                \t\t\t\t\t"title": "Configured",
                                \t\t\t\t\t"type": "\(String(describing: keyValuePairs[key]!["valueType"]!))"
                                \t\t\t\t}
                                \t\t\t]
                                \t\t}\(keyDelimiter)
                                """
                                preferenceDomainFileOp.write(text.data(using: String.Encoding.utf8)!)
                                
                             }   // for (key, _) in packagesDict - end
                            preferenceDomainFileOp.seekToEndOfFile()
                            preferenceDomainFileOp.write("\t}\n}".data(using: String.Encoding.utf8)!)
                            preferenceDomainFileOp.closeFile()
                        }
                    } else {
                        // preference domain required
                        print("preference domain required")
                    }   // if preferenceDomain_TextField != "" - end
                    
                    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keys_TableView.delegate   = self
        keys_TableView.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func quit_Button(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    

}


extension ViewController: NSTableViewDataSource {

  func numberOfRows(in keys_TableView: NSTableView) -> Int {
    return preferenceKeys_TableArray?.count ?? 0
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
        guard let item = preferenceKeys_TableArray?[row] else {
            return nil
        }
        
        print("item: \(item)")
        
        
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

}
