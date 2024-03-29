//
//  Credentials.swift
//  Object Info
//
//  Created by Leslie Helou on 9/20/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation
import Security

let kSecAttrAccountString          = NSString(format: kSecAttrAccount)
let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)
let keychainQ                      = DispatchQueue(label: "com.jamf.objectinfo", qos: DispatchQoS.background)
let prefix                         = "Object Info"
let sharedPrefix                   = "JPMA"
let accessGroup                    = "PS2F6S478M.jamfie.SharedJPMA"

class Credentials {
    
    static let shared = Credentials()
    private init() { }
    
    var userPassDict = [String:String]()
    
    func save(service: String, account: String, credential: String) {
        if service != "" && account != "" && service.first != "/" {
            var theService = service
        
            if useApiClient == 1 {
                theService = "apiClient-" + theService
            }
            
            let keychainItemName = sharedPrefix + "-" + theService
            print("[credentials.save] save credentials for \(keychainItemName), account: \(account)")
            if let password = credential.data(using: String.Encoding.utf8) {
                keychainQ.async { [self] in
                    var keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                        kSecAttrService as String: keychainItemName,
                                                        kSecAttrAccessGroup as String: accessGroup,
                                                        kSecUseDataProtectionKeychain as String: true,
                                                        kSecAttrAccount as String: account,
                                                        kSecValueData as String: password]
                    
                    
                    // see if credentials already exist for server
                    let accountCheck = retrieve(service: service, account: account)
//                    let accountCheck = retrieve(service: keychainItemName, account: account)
                    if accountCheck.count == 0 {
                        // try to add new credentials, if account exists we'll try updating it
                        print("[credentials.save] save credentials for new account: \(account)")
                        let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                        if (addStatus != errSecSuccess) {
                            if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                print("[addStatus] New credentials write failed for \(account): \(addErr)")
                                WriteToLog.shared.message(stringOfText: "[credentials.addStatus] New credentials write failed for \(account): \(addErr)")
                                let deleteStatus = SecItemDelete(keychainQuery as CFDictionary)
                                print("[Credentials.save] the deleteStatus: \(deleteStatus)")
                                sleep(1)
                                let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                                if (addStatus != errSecSuccess) {
                                    if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                        print("[addStatus] New credentials write failed for \(account) after deleting: \(addErr)")
                                        WriteToLog.shared.message(stringOfText: "[credentials.addStatus] New credentials write failed for \(account) after deleting: \(addErr)")
                                    }
                                }
                            }
                        } else {
                            print("[credentials.save] saved credentials for new account: \(account)")
                        }
                    } else {
                        // credentials already exist, try to update
                        print("[credentials.save] update credentials for account: \(account)")
                        keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                         kSecAttrService as String: keychainItemName,
                                         kSecMatchLimit as String: kSecMatchLimitOne,
                                         kSecReturnAttributes as String: true]
                        
                        for (username, password) in accountCheck {
                            if account == username && credential != password {
                                // credentials already exist, try to update if necessary
                                let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataString:password] as [NSString : Any] as CFDictionary)
                                WriteToLog.shared.message(stringOfText: "[credentials.save] result of credentials update: \(updateStatus)")

                            }
                        }
                    }
                }
            }
        }
    }   // func save - end
    
    func retrieve(service: String, account: String, whichServer: String = "") -> [String:String] {
        
        var keychainResult = [String:String]()
        var theService = service
        
//        if account != "" {
//            theService = account + "-" + theService
//        }
//        print("[credentials] JamfProServer.sourceApiClient: \(JamfProServer.sourceUseApiClient)")
        
        if useApiClient == 1 {
            theService = "apiClient-" + theService
        }
        
        var keychainItemName = sharedPrefix + "-" + theService
//        print("[retrieve] keychainItemName: \(keychainItemName)")
        // look for common keychain item
        keychainResult = itemLookup(service: keychainItemName, account: account)
        // look for legacy keychain item
        if keychainResult.count == 0 {
            keychainItemName = "\(prefix) - \(theService)"
            keychainResult   = oldItemLookup(service: keychainItemName, account: account)
        }
        
        return keychainResult
    }
    
    private func itemLookup(service: String, account: String) -> [String:String] {
        
//        print("[Credentials.itemLookup] start search for: \(service)")
   
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecAttrAccount as String: account,
                                            kSecAttrAccessGroup as String: accessGroup,
                                            kSecUseDataProtectionKeychain as String: true,
                                            kSecMatchLimit as String: kSecMatchLimitAll,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        
        var items_ref: CFTypeRef?
        
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &items_ref)
        guard status != errSecItemNotFound else {
            print("[Credentials.itemLookup] lookup error occurred for \(service): \(status.description)")
            return [:]
            
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let items = items_ref as? [[String: Any]] else {
            print("[Credentials.itemLookup] unable to read keychain item: \(service)")
            return [:]
        }
        for item in items {
            if let account = item[kSecAttrAccount as String] as? String, let passwordData = item[kSecValueData as String] as? Data {
                let password = String(data: passwordData, encoding: String.Encoding.utf8)
                userPassDict[account] = password ?? ""
            }
        }

//        print("[Credentials.itemLookup] keychain item count: \(userPassDict.count) for \(service)")
        return userPassDict
    }
    
    private func oldItemLookup(service: String, account: String) -> [String:String] {
        
//        print("[Credentials.oldItemLookup] start search for: \(service)")

        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecAttrAccount as String: account,
                                            kSecMatchLimit as String: kSecMatchLimitOne,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            print("[Credentials.oldItemLookup] lookup error occurred: \(status.description)")
            return [:]
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
            return [:]
        }
        userPassDict[account] = password
        return userPassDict
    }
}

