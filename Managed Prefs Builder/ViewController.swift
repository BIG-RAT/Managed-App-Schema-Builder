//
//  ViewController.swift
//  Managed Prefs Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var keys_Button: NSPopUpButton!
    @IBOutlet var description_TextView: NSTextView!
    @IBOutlet weak var title_TextField: NSTextFieldCell!
    @IBOutlet weak var valueType_Button: NSPopUpButton!
    @IBOutlet weak var value_TextField: NSTextField!
    
    @IBOutlet weak var valueTypeArray_ScrollView: NSScrollView!
    
    
    @IBOutlet var valueTypeArray_TextView: NSTextView!
    
    @IBOutlet weak var keys_TableView: NSTableView!
    var preferenceKeys_TableArray: [String]?
    
    
    var keysDict = [String:[String:Any]]()
    var keysArray = [String]()
    
    var valueType = ""
    var keyName   = ""
        
        @IBAction func selectFile_Button(_ sender: NSButton) {
            
            let path = selectFile()
//            var lines = [String]()
            var json: Any?
//            summary_TextField.font = NSFont.init(name: "Monaco", size: 10.0)
            
//            self.summary_TextField.string = ""
            
            if (path != "") {
                //    var err = NSError?()
                print("path: \(path)")
                do {
                    let fileUrl = URL(fileURLWithPath: path)
                    // Getting data from JSON file using the file URL
                    let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                    json = try? JSONSerialization.jsonObject(with: data)
                    let manifestJson = json as? [String: Any]
//                    for (key, _) in manifestJson! {
//                        print("key: \(key)")
//                    }
                    let properties = manifestJson!["properties"] as! [String:Any]
                    keysArray.removeAll()
                    for (domain, _) in properties {
                        print("domain: \(domain)")
//                        keys_Button.addItem(withTitle: domain)
                        keysArray.append(domain)
                        keysDict[domain] = properties[domain] as? [String : Any]
//                        description_TextView.string = keysDict[domain]!["description"] as! String
                    }
                    keysArray.sort()
                    keys_Button.addItems(withTitles: keysArray)
                    if keysArray.count > 0 {
                        preferenceKeys_TableArray = keysArray
                        keys_TableView.reloadData()
                    }
//                    print("\(json)")
                } catch {
                    print("couldn't reach json file")
                }
                
                do {
                    let text = try String(contentsOfFile: path)
                    //let text = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &err)
                    
                    if (text != "") {
//                        lines = text.components(separatedBy: "\n")
                        
    //                    for line in lines {
    //                        print(line)
    //                    }
                        DispatchQueue.main.async {
//                            let trimmedSummary = ParseSummary().parse(fileArray: lines)
//                            for summaryLine in trimmedSummary {
//                                self.summary_TextField.string = self.summary_TextField.string + summaryLine
//                            }

                        }
                    } else {
                        print("cancelled")
                    }
                } catch {
                    print("unable to read file")
//                    self.summary_TextField.string = "Unable to read file."
//                    self.summary_TextField.string = "Try to resave the summary with a plain text editor."
                }
            }
            
        }
    
    
    @IBAction func selectDomain_Action(_ sender: Any) {
        
        DispatchQueue.main.async {
            let theRow = self.keys_TableView.selectedRow
            self.keyName = (self.preferenceKeys_TableArray?[theRow])!
            
            print("keyName: \(self.keyName)")
            let anyOf = self.keysDict[self.keyName]!["anyOf"] as! [[String:Any]]
            if anyOf.count > 1 {
                self.valueType = anyOf[1]["type"] as! String
            } else {
                self.valueType = "plist"
            }

            var keyTitle = self.keysDict[self.keyName]!["title"] as! String
            keyTitle = keyTitle.replacingOccurrences(of: " - ", with: "\n")
            self.title_TextField.stringValue = keyTitle
            self.description_TextView.string = self.keysDict[self.keyName]!["description"] as! String
//
            self.value_TextField.stringValue = "Value (\(self.valueType)):"
            switch self.valueType {
            case "boolean":
                self.valueType_Button.selectItem(at: 0)
                self.valueType_Button.isHidden = false
                self.valueTypeArray_ScrollView.isHidden = true
            case "array","string","integer","plist":
                self.valueType_Button.isHidden = true
                self.valueTypeArray_ScrollView.isHidden = false
            default:
                self.valueType_Button.isHidden = true
                self.valueTypeArray_ScrollView.isHidden = true
            }
        }
    }
    
//    @IBAction func selectDomain_Button(_ sender: Any) {
//
//        var valueType = ""
//
//        let domainTitle = "\(keys_Button.titleOfSelectedItem ?? "")"
//        let anyOf = keysDict[domainTitle]!["anyOf"] as! [[String:Any]]
//        if anyOf.count > 1 {
//            valueType = anyOf[1]["type"] as! String
//        } else {
//            valueType = "plist"
//        }
//
//        var keyTitle = keysDict[domainTitle]!["title"] as! String
//        keyTitle = keyTitle.replacingOccurrences(of: " - ", with: "\n")
//        title_TextField.stringValue = keyTitle
//        description_TextView.string = keysDict[domainTitle]!["description"] as! String
//
//        DispatchQueue.main.async {
//            self.value_TextField.stringValue = "Value (\(valueType)):"
//            switch valueType {
//            case "boolean":
//                self.valueType_Button.isHidden = false
//                self.valueTypeArray_ScrollView.isHidden = true
//            case "array","string","integer","plist":
//                self.valueType_Button.isHidden = true
//                self.valueTypeArray_ScrollView.isHidden = false
//            default:
//                self.valueType_Button.isHidden = true
//                self.valueTypeArray_ScrollView.isHidden = true
//            }
//        }
//    }
    
    
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

}


extension ViewController: NSTableViewDataSource {

  func numberOfRows(in keys_TableView: NSTableView) -> Int {
    return preferenceKeys_TableArray?.count ?? 0
  }
}

extension ViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let StateCell = "StateCell_Id"
        static let NameCell = "NameCell_Id"
    }
    
    func tableView(_ object_TableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
    
//        print("[func tableView] item: \(unusedItems_TableArray?[row] ?? nil)")
        guard let item = preferenceKeys_TableArray?[row] else {
            return nil
        }
        
        
        if tableColumn == object_TableView.tableColumns[0] {
//            image = item.icon
        } else if tableColumn == object_TableView.tableColumns[1] {
            text = "\(item)"
            cellIdentifier = CellIdentifiers.NameCell
        }
//        } else if tableColumn == object_TableView.tableColumns[1] {
//            let result:NSPopUpButton = tableView.make(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "objectType"), owner: self) as! NSPopUpButton
//            cellIdentifier = CellIdentifiers.TypeCell
//        }
    
        if let cell = object_TableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

}
