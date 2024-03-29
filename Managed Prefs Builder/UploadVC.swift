//
//  LoginVC.swift
//  Object Info
//

import Cocoa
import Foundation

protocol SendingLoginInfoDelegate {
    func sendLoginInfo(loginInfo: (String,String,String,String,Int))
}

class LoginVC: NSViewController, URLSessionDelegate, NSTextFieldDelegate {
    
    var delegate: SendingLoginInfoDelegate? = nil
    
    @IBOutlet weak var spinner_PI: NSProgressIndicator!
    
    @IBOutlet weak var displayName_Label: NSTextField!
    @IBOutlet weak var displayName_TextField: NSTextField!
    @IBOutlet weak var selectServer_Button: NSPopUpButton!
    
    @IBOutlet weak var useApiClient_button: NSButton!
    
    @IBAction func selectServer_Action(_ sender: Any) {
        if selectServer_Button.titleOfSelectedItem == "Add Server..." {
            
            displayName_TextField.becomeFirstResponder()
            
            displayName_TextField.insertText("hello")
            displayName_Label.stringValue = "Display Name:"
            displayName_TextField.stringValue = ""
            selectServer_Button.isHidden = true
            displayName_TextField.isHidden = false
            serverURL_Label.isHidden = false
            jamfProServer_textfield.isHidden = false
            jamfProServer_textfield.isEditable = true
            jamfProServer_textfield.stringValue = ""
            jamfProUsername_textfield.stringValue = ""
            jamfProPassword_textfield.stringValue = ""
            saveCreds_button.state = NSControl.StateValue(rawValue: 0)
            defaults.set(0, forKey: "saveCreds")
            hideCreds_button.isHidden = true
            quit_Button.title  = "Cancel"
            login_Button.title = "Add"
            
            setWindowSize(setting: 2)
        } else {
            if NSEvent.modifierFlags.contains(.option) {
                    let selectedServer =  selectServer_Button.titleOfSelectedItem!
                    let response = Alert.shared.display(header: "", message: "Are you sure you want to remove \(selectedServer) from the list?", secondButton: "Cancel")
                    if response == "Cancel" {
                        return
                    } else {
                        for (displayName, _) in availableServersDict {
                            if displayName == selectedServer {
                                availableServersDict[displayName] = nil
                                selectServer_Button.removeItem(withTitle: selectedServer)
                                sortedDisplayNames.removeAll(where: {$0 == displayName})
                            }
                        }
                        if saveServers {
                            sharedDefaults!.set(availableServersDict, forKey: "serversDict")
                        }
                        if sortedDisplayNames.firstIndex(of: lastServer) != nil {
                            selectServer_Button.selectItem(withTitle: lastServer)
                        } else {
                            jamfProServer_textfield.stringValue   = ""
                            jamfProUsername_textfield.stringValue = ""
                            jamfProPassword_textfield.stringValue = ""
                            selectServer_Button.selectItem(withTitle: "")
                        }
                    }
                
                return
            }
            displayName_Label.stringValue = "Server:"
            selectServer_Button.isHidden = false
            displayName_TextField.isHidden = true
            serverURL_Label.isHidden = false
            jamfProServer_textfield.isHidden = false
            jamfProServer_textfield.isEditable = false
            hideCreds_button.isHidden = false
            displayName_TextField.stringValue = selectServer_Button.titleOfSelectedItem ?? ""
            
//            print("[LoginVC.viewDidLoad] displayName_TextField.stringValue: \(displayName_TextField.stringValue)")
//            print("[LoginVC.viewDidLoad] availableServersDict: \(availableServersDict)")
            
            if let loginInfo = availableServersDict[selectServer_Button.titleOfSelectedItem ?? ""], let serverUrl = loginInfo["server"] as? String {
                let theAccount = loginInfo["account"] as? String ?? ""
                jamfProServer_textfield.stringValue = "\(serverUrl)"
                jamfProUsername_textfield.stringValue = "\(theAccount)"
                credentialsCheck()
            }
            quit_Button.title  = "Quit"
            login_Button.title = "Login"
            
        }
    }
    @IBOutlet weak var selectServer_Menu: NSMenu!
    
    @IBOutlet weak var hideCreds_button: NSButton!
    
    @IBOutlet weak var serverURL_Label: NSTextField!
    
    @IBOutlet weak var jamfProServer_textfield: NSTextField!
    @IBOutlet weak var jamfProUsername_textfield: NSTextField!
    @IBOutlet weak var jamfProPassword_textfield: NSSecureTextField!
    
    @IBOutlet weak var username_label: NSTextField!
    @IBOutlet weak var password_label: NSTextField!
    
    
    @IBOutlet weak var login_Button: NSButton!
    @IBOutlet weak var quit_Button: NSButton!
    
    var availableServersDict   = [String:[String:AnyObject]]()
        
    var accountDict            = [String:String]()
    var currentServer          = ""
    var categoryName           = ""
    var uploadCount            = 0
    var totalObjects           = 0
    var uploadsComplete        = false
    var sortedDisplayNames     = [String]()
    var lastServer             = ""
//    var lastServerDN           = ""

    @IBOutlet weak var saveCreds_button: NSButton!
    
    @IBAction func hideCreds_action(_ sender: NSButton) {
        print("[hideCreds_action] button state: \(hideCreds_button.state.rawValue)")
        hideCreds_button.image = (hideCreds_button.state.rawValue == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
        defaults.set("\(hideCreds_button.state.rawValue)", forKey: "hideCreds")
        setWindowSize(setting: hideCreds_button.state.rawValue)
    }
    
    @IBAction func login_action(_ sender: Any) {
        spinner_PI.isHidden = false
        spinner_PI.startAnimation(self)
        didRun = true
        
        var theSender = ""
//        var theButton: NSButton?
        if (sender as? NSButton) != nil {
            theSender = (sender as? NSButton)!.title
        } else {
            theSender = sender as! String
        }
        print("[login_action] sender: \(theSender)")
        if theSender == "Add" {
            JamfProServer.server      = jamfProServer_textfield.stringValue.trimTrailingSlash
            JamfProServer.username    = jamfProUsername_textfield.stringValue
            JamfProServer.password    = jamfProPassword_textfield.stringValue
        }
//        print("[login_action] destination: \(JamfProServer.server)")
//        print("[login_action] username: \(JamfProServer.username)")
//        print("[login_action] userpass: \(JamfProServer.password)")
        
        // check for update/removal of server display name
        if jamfProServer_textfield.stringValue == "" {
            let serverToRemove = (theSender == "Login") ? "\(selectServer_Button.titleOfSelectedItem ?? "")":displayName_TextField.stringValue
            let deleteReply = Alert.shared.display(header: "Attention:", message: "Do you wish to remove \(serverToRemove) from the list?", secondButton: "Cancel")
            if deleteReply != "Cancel" && serverToRemove != "Add Server..." {
                if availableServersDict[serverToRemove] != nil {
                    let serverIndex = selectServer_Menu.indexOfItem(withTitle: serverToRemove)
                    selectServer_Menu.removeItem(at: serverIndex)
                    if defaults.string(forKey: "currentServer") == availableServersDict[serverToRemove]!["server"] as? String {
                        print("[login_Action] blank currentServer")
                        defaults.set("", forKey: "currentServer")
                    }
                    availableServersDict[serverToRemove]  = nil
                    lastServer                            = ""
                    jamfProServer_textfield.stringValue   = ""
                    jamfProUsername_textfield.stringValue = ""
                    jamfProPassword_textfield.stringValue = ""
                    if saveServers {
                        sharedDefaults!.set(availableServersDict, forKey: "serversDict")
                    }
                    selectServer_Button.selectItem(withTitle: "")
                }
                
                spinner_PI.stopAnimation(self)
                return
            } else {
                spinner_PI.stopAnimation(self)
                return
            }
        } else if jamfProServer_textfield.stringValue != availableServersDict[selectServer_Button.titleOfSelectedItem!]?["server"] as? String && selectServer_Button.titleOfSelectedItem ?? "" != "Add Server..." {
            let serverToUpdate = (theSender == "Login") ? "\(selectServer_Button.titleOfSelectedItem ?? "")":displayName_TextField.stringValue.fqdnFromUrl
            let updateReply = Alert.shared.display(header: "Attention:", message: "Do you wish to update the URL for \(serverToUpdate) to: \(jamfProServer_textfield.stringValue)", secondButton: "Cancel")
            if updateReply != "Cancel" && serverToUpdate != "Add Server..." {
                // update server URL
                availableServersDict[serverToUpdate]?["server"] = jamfProServer_textfield.stringValue as AnyObject
                if saveServers {
                    sharedDefaults!.set(availableServersDict, forKey: "serversDict")
                }
            } else {
                jamfProServer_textfield.stringValue = availableServersDict[selectServer_Button.titleOfSelectedItem!]?["server"] as! String
            }
        }
        
        isRunning = true
        if theSender == "Login" {
            JamfProServer.validToken = false
            JamfProServer.server = jamfProServer_textfield.stringValue.trimTrailingSlash
            JamfProServer.username = jamfProUsername_textfield.stringValue
            JamfProServer.password = jamfProPassword_textfield.stringValue
            
//            print("[Login] server: \(JamfProServer.server)")
//            print("[Login] user: \(jamfProUsername_textfield.stringValue)")
//            print("[Login] pass: \(jamfProPassword_textfield.stringValue.prefix(2))")
            
            
            let jamfUtf8Creds = "\(jamfProUsername_textfield.stringValue):\(jamfProPassword_textfield.stringValue)".data(using: String.Encoding.utf8)
            JamfProServer.base64Creds = (jamfUtf8Creds?.base64EncodedString())!
            JamfPro.shared.getToken(whichServer: "source", serverUrl: JamfProServer.server) { [self]
                authResult in
                isRunning = false
                login_Button.isEnabled = true
                
                let (statusCode,theResult) = authResult
                WriteToLog.shared.message(stringOfText: "[getToken] status code: \(statusCode)")
                if theResult == "success" {
                    // invalidate token - todo
                    defaults.set(selectServer_Button.titleOfSelectedItem, forKey: "currentServer")
                    defaults.set(jamfProUsername_textfield.stringValue, forKey: "username")
                    let currentSettings = availableServersDict[selectServer_Button.titleOfSelectedItem ?? ""] ?? [:]
                    let currentdbType = currentSettings["dbType"] as? String ?? ""
                    
                    availableServersDict.updateValue(["useApiClient": useApiClient_button.state.rawValue as AnyObject, "server": JamfProServer.server as AnyObject, "date": Date() as AnyObject, "account": JamfProServer.username as AnyObject, "dpType": currentdbType as AnyObject], forKey: selectServer_Button.titleOfSelectedItem!)
                    print("[Login] availableServersDict: \(availableServersDict)")
                    
                    sharedDefaults!.set(availableServersDict, forKey: "serversDict")
                    
                    let dataToBeSent = (selectServer_Button.titleOfSelectedItem!, JamfProServer.server, JamfProServer.username, JamfProServer.password, saveCreds_button.state.rawValue)
                    delegate?.sendLoginInfo(loginInfo: dataToBeSent)
                    dismiss(self)
                }
                spinner_PI.stopAnimation(self)
            }
        } else {
            // add server
            if displayName_TextField.stringValue == "" {
                let nameReply = Alert.shared.display(header: "Attention:", message: "Display name cannot be blank.\nUse \(jamfProServer_textfield.stringValue.fqdnFromUrl)?", secondButton: "Cancel")
                if nameReply == "Cancel" {
                    spinner_PI.stopAnimation(self)
                    return
                } else {
                    displayName_TextField.stringValue = jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl
                }
            }   // no display name - end
            
            login_Button.isEnabled = false
            
            if JamfProServer.server.prefix(4) != "http" {
                jamfProServer_textfield.stringValue = "https://\(JamfProServer.server)"
                JamfProServer.server = jamfProServer_textfield.stringValue.trimTrailingSlash
            }
            
            let jamfUtf8Creds = "\(JamfProServer.username):\(JamfProServer.password)".data(using: String.Encoding.utf8)
            JamfProServer.base64Creds = (jamfUtf8Creds?.base64EncodedString())!
            JamfPro.shared.getToken(whichServer: "source", serverUrl: JamfProServer.server) { [self]
                authResult in
                
                isRunning = false
                login_Button.isEnabled = true
                
                let (statusCode,theResult) = authResult
                if theResult == "success" {
                    // invalidate token - todo
//
//                    header_TextField.isHidden          = true
//                    header_TextField.wantsLayer        = true
//                    header_TextField.stringValue       = ""
//                    header_TextField.frame.size.height = 0.0
                    
                    sortedDisplayNames.append(displayName_TextField.stringValue)
                    while availableServersDict.count >= maxServerList {
                        // find last used server
                        var lastUsedDate = Date()
                        var serverName   = ""
                        for (displayName, serverInfo) in availableServersDict {
                            if let _ = serverInfo["date"] {
                                if (serverInfo["date"] as! Date) < lastUsedDate {
                                    lastUsedDate = serverInfo["date"] as! Date
                                    serverName = displayName
                                }
                            } else {
                                serverName = displayName
                                break
                            }
                        }
                        availableServersDict[serverName] = nil
                    }
                    
//                    availableServersDict[displayName_TextField.stringValue] = ["server":JamfProServer.server as AnyObject,"date":Date() as AnyObject]
                    if saveServers {
                        sharedDefaults!.set(availableServersDict, forKey: "serversDict")
                    }
                    
                    defaults.set(displayName_TextField.stringValue, forKey: "currentServer")
                    defaults.set(jamfProUsername_textfield.stringValue, forKey: "username")
                    
                    print("[login_action] availableServers: \(availableServersDict)")
                    
                    setSelectServerButton(listOfServers: sortedDisplayNames)
                    selectServer_Button.selectItem(withTitle: displayName_TextField.stringValue)
                    displayName_Label.stringValue = "Server:"
                    selectServer_Button.isHidden = false
                    displayName_TextField.isHidden = true
                    quit_Button.title  = "Quit"
                    login_Button.title = "Login"
                    
                    login_action("Login")
                } else {
                    spinner_PI.stopAnimation(self)
                    _ = Alert.shared.display(header: "Attention:", message: "Failed to generate token. HTTP status code: \(statusCode)", secondButton: "")
                }
            }
        }
    }
    
    @IBAction func quit_Action(_ sender: NSButton) {
        if sender.title == "Quit" {
            dismiss(self)
            NSApplication.shared.terminate(self)
        } else if login_Button.title == "Add" {
//            header_TextField.isHidden = true
//            header_TextField.wantsLayer = true
//            header_TextField.stringValue = ""
//            header_TextField.frame.size.height = 0.0
            displayName_Label.stringValue = "Server:"
            selectServer_Button.isHidden = false
            displayName_TextField.isHidden = true
            serverURL_Label.isHidden = false
            jamfProServer_textfield.isHidden = false
            jamfProServer_textfield.isEditable = false
            hideCreds_button.isHidden = false
            if lastServer != "" {
                var tmpName = ""
                for (dName, serverInfo) in availableServersDict {
                    tmpName = dName
                    if (serverInfo["server"] as! String) == lastServer { break }
                }
                selectServer_Button.selectItem(withTitle: tmpName)
                displayName_TextField.stringValue = tmpName
                jamfProServer_textfield.stringValue = ((availableServersDict[tmpName]?["server"])! as! String).trimTrailingSlash
                credentialsCheck()
            } else {
                login_Button.isEnabled              = false
                jamfProServer_textfield.isEnabled   = false
                jamfProUsername_textfield.isEnabled = false
                jamfProPassword_textfield.isEnabled = false
            }
            quit_Button.title  = "Quit"
            login_Button.title = "Login"
        } else {
            dismiss(self)
        }
    }
    
    @IBAction func saveCredentials_Action(_ sender: Any) {
        if saveCreds_button.state.rawValue == 1 {
            defaults.set(1, forKey: "saveCreds")
        } else {
            defaults.set(0, forKey: "saveCreds")
        }
    }
    
    @IBAction func useApiClient_action(_ sender: NSButton) {
        setLabels()
        defaults.set(useApiClient_button.state.rawValue, forKey: "useApiClient")
        fetchPassword()
    }
    
    func fetchPassword() {
        let accountDict = Credentials.shared.retrieve(service: jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl, account: jamfProUsername_textfield.stringValue)
        
        if accountDict.count == 1 {
            for (username, password) in accountDict {
                jamfProUsername_textfield.stringValue = username
                jamfProPassword_textfield.stringValue = password
            }
        } else {
            jamfProPassword_textfield.stringValue = ""
        }
    }

    func setLabels() {
        useApiClient = useApiClient_button.state.rawValue
        if useApiClient == 0 {
            username_label.stringValue = "Username:"
            password_label.stringValue = "Password:"
        } else {
            username_label.stringValue = "Client ID:"
            password_label.stringValue = "Client Secret:"
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            jamfProPassword_textfield.stringValue = ""
            switch textField.identifier!.rawValue {
            case "server":
                let accountDict = Credentials.shared.retrieve(service: jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl, account: jamfProUsername_textfield.stringValue)
                
                if accountDict.count == 1 {
                    for (username, password) in accountDict {
                        jamfProUsername_textfield.stringValue = username
                        jamfProPassword_textfield.stringValue = password
                    }
                }
            case "username":
                let accountDict = Credentials.shared.retrieve(service: jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl, account: jamfProUsername_textfield.stringValue)
                if accountDict.count != 0 {
                    for (username, password) in accountDict {
                        if username == jamfProUsername_textfield.stringValue {
                            jamfProUsername_textfield.stringValue = username
                            jamfProPassword_textfield.stringValue = password
                        }
                    }
                }
            default:
                break
            }
        }
    }
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            jamfProPassword_textfield.stringValue = ""
            switch textField.identifier!.rawValue {
            case "server":
                if jamfProUsername_textfield.stringValue != "" || jamfProPassword_textfield.stringValue != "" {
                    let accountDict = Credentials.shared.retrieve(service: jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl, account: jamfProUsername_textfield.stringValue)
                    
                    if accountDict.count == 1 {
                        for (username, password) in accountDict {
                            jamfProUsername_textfield.stringValue = username
                            jamfProPassword_textfield.stringValue = password
                        }
//                        setWindowSize(setting: 0)
                    } else {
                        jamfProUsername_textfield.stringValue = ""
                        jamfProPassword_textfield.stringValue = ""
//                        setWindowSize(setting: 1)
                    }
                }
            default:
                break
            }
        }
    }
    
    func credentialsCheck() {
        let accountDict = Credentials.shared.retrieve(service: jamfProServer_textfield.stringValue.trimTrailingSlash.fqdnFromUrl, account: jamfProUsername_textfield.stringValue)
        
        if accountDict.count != 0 {
            for (username, password) in accountDict {
//                print("[credentialsCheck] username: \(username)")
                if username == jamfProUsername_textfield.stringValue || accountDict.count == 1 {
                    jamfProUsername_textfield.stringValue = username
                    jamfProPassword_textfield.stringValue = password
                }
//                let windowState = (defaults.integer(forKey: "hideCreds") == 1) ? 1:0
//                hideCreds_button.isHidden = false
//                saveCreds_button.state = NSControl.StateValue(rawValue: 1)
//                defaults.set(1, forKey: "saveCreds")
//                setWindowSize(setting: windowState)
            }
        } else {
//            if useApiClient == 0 {
//                jamfProUsername_textfield.stringValue = defaults.string(forKey: "username") ?? ""
//            } else {
//                jamfProUsername_textfield.stringValue = ""
//            }
            jamfProPassword_textfield.stringValue = ""
            setWindowSize(setting: 1)
        }
        JamfProServer.server   = jamfProServer_textfield.stringValue.trimTrailingSlash
        JamfProServer.username = jamfProUsername_textfield.stringValue
        JamfProServer.password = jamfProPassword_textfield.stringValue
        
    }
    
    func setSelectServerButton(listOfServers: [String]) {
        // case insensitive sort
        sortedDisplayNames = listOfServers.sorted{ $0.localizedCompare($1) == .orderedAscending }
        selectServer_Button.removeAllItems()
        selectServer_Button.addItems(withTitles: sortedDisplayNames)
        let serverCount = selectServer_Menu.numberOfItems
        selectServer_Menu.insertItem(NSMenuItem.separator(), at: serverCount)
        selectServer_Button.addItem(withTitle: "Add Server...")
    }
    
    func setWindowSize(setting: Int) {
//        print("[setWindowSize] setting: \(setting)")
        if setting == 0 {
            preferredContentSize = CGSize(width: 518, height: 85)
            hideCreds_button.toolTip = "show username/password fields"
            jamfProServer_textfield.isHidden   = true
            jamfProUsername_textfield.isHidden = true
            jamfProPassword_textfield.isHidden = true
            serverURL_Label.isHidden           = true
            username_label.isHidden            = true
            password_label.isHidden            = true
            saveCreds_button.isHidden          = true
        } else if setting == 1 {
            preferredContentSize = CGSize(width: 518, height: 208)
            hideCreds_button.toolTip = "hide username/password fields"
            jamfProServer_textfield.isHidden   = false
            jamfProUsername_textfield.isHidden = false
            jamfProPassword_textfield.isHidden = false
            serverURL_Label.isHidden           = false
            username_label.isHidden            = false
            password_label.isHidden            = false
            saveCreds_button.isHidden          = false
        } else if setting == 2 {
            preferredContentSize = CGSize(width: 518, height: 208)
            hideCreds_button.toolTip = "hide username/password fields"
            jamfProServer_textfield.isHidden   = false
            jamfProUsername_textfield.isHidden = false
            jamfProPassword_textfield.isHidden = false
            serverURL_Label.isHidden           = false
            username_label.isHidden            = false
            password_label.isHidden            = false
            saveCreds_button.isHidden          = false
        }
//        hideCreds_button.state = NSControl.StateValue(rawValue: setting)
//        
//        hideCreds_button.image = (setting == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // to clear saved list of servers
//        defaults.set([:] as [String:[String:AnyObject]], forKey: "serversDict")
//        sharedDefaults!.set([:] as [String:[String:AnyObject]], forKey: "serversDict")
        // clear lastServer
//        defaults.set("", forKey: "currentServer")
        
//        header_TextField.stringValue = ""
//        header_TextField.wantsLayer = true
//        let textFrame = NSTextField(frame: NSRect(x: 0, y: 0, width: 268, height: 1))
//        header_TextField.frame = textFrame.frame
        
        let hideCredsState = defaults.integer(forKey: "hideCreds")
        hideCreds_button.image = (hideCredsState == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
        hideCreds_button.state = NSControl.StateValue(rawValue: hideCredsState)
        setWindowSize(setting: hideCreds_button.state.rawValue)

        jamfProServer_textfield.delegate   = self
        jamfProUsername_textfield.delegate = self
//        jamfProPassword_textfield.delegate = self
        
        lastServer = defaults.string(forKey: "currentServer") ?? ""
        print("[loginVC.viewDidLoad] lastServer: \(lastServer)")
        var foundServer = false
        
        useApiClient = defaults.integer(forKey: "useApiClient")
        useApiClient_button.state = NSControl.StateValue(rawValue: useApiClient)
        setLabels()
                
        // check shared settings
//        print("[viewDidLoad] sharedSettingsPlistUrl: \(sharedSettingsPlistUrl.path)")
        if !FileManager.default.fileExists(atPath: sharedSettingsPlistUrl.path) {
            sharedDefaults!.set(Date(), forKey: "created")
            sharedDefaults!.set([String:AnyObject](), forKey: "serversDict")
        }
        if (sharedDefaults!.object(forKey: "serversDict") as? [String:AnyObject] ?? [:]).count == 0 {
            sharedDefaults!.set(availableServersDict, forKey: "serversDict")
        }
        
        // read list of saved servers
        availableServersDict = sharedDefaults!.object(forKey: "serversDict") as? [String:[String:AnyObject]] ?? [:]
//        print("[LoginVC.viewDidLoad] availableServersDict: \(availableServersDict)")
        
        // trim list of servers to maxServerList
        while availableServersDict.count >= maxServerList {
            // find last used server
            var lastUsedDate = Date()
            var serverName   = ""
            for (displayName, serverInfo) in availableServersDict {
                if let _ = serverInfo["date"] {
                    if (serverInfo["date"] as! Date) < lastUsedDate {
                        lastUsedDate = serverInfo["date"] as! Date
                        serverName = displayName
                    }
                } else {
                    serverName = displayName
                    break
                }
            }
            print("removing \(serverName) from the list")
            availableServersDict[serverName] = nil
        }
//        print("lastServer: \(lastServer)")
        var serverUrl = ""
        if availableServersDict.count > 0 {
            for (displayName, serverInfo) in availableServersDict {
                if displayName != "" {
                    sortedDisplayNames.append(displayName)
                    if displayName == lastServer && lastServer != "" {
                        foundServer = true
                        serverUrl = serverInfo["server"] as! String
                    }
                } else {
                    availableServersDict[displayName] = nil
                }
            }
        } else {
                jamfProServer_textfield.stringValue = ""
                setSelectServerButton(listOfServers: [])
                selectServer_Button.selectItem(withTitle: "Add Server...")
                login_Button.title = "Add"
                
                selectServer_Action(self)
                setWindowSize(setting: 2)
        }
        
        setSelectServerButton(listOfServers: sortedDisplayNames)
        if foundServer {
            selectServer_Button.selectItem(withTitle: lastServer)
            jamfProServer_textfield.stringValue = serverUrl
            jamfProUsername_textfield.stringValue = defaults.string(forKey: "username") ?? ""
            if jamfProServer_textfield.stringValue != "" {
                credentialsCheck()
            }
        }

        saveCreds_button.state = NSControl.StateValue(defaults.integer(forKey: "saveCreds"))
        
//        print("[LoginVC.viewDidLoad] availableServersDict: \(availableServersDict)")

        // bring app to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

