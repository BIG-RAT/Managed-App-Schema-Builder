//
//  ApiAction.swift
//  jamfcpr
//
//  Created by Leslie Helou on 6/25/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

class ApiAction: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    static let shared = ApiAction()
    private override init() { }
    
    var theApiQ = OperationQueue() // create operation queue for API calls
    init(theApiQ: OperationQueue = OperationQueue()) {
        self.theApiQ = theApiQ
    }
//    func updateXML(server: String, creds: String, endpointType: String, xmlData: String, restMethod: String = "POST", objectId: String = "0", completion: @escaping (_ returnInfo: [String:String]) -> Void) {
    func updateXML(server: String, uploadFilename: String, fullName: String, destinationUser: String, completion: @escaping (_ returnInfo: [String:String]) -> Void) {
        
        var workingUrl    = ""
        var responseData  = ""
//        var objectId      = "0"
//        var restMethod    = "POST"
        var returnInfo   = [String:String]()
        var endpointType = "packages"
    
        theApiQ.maxConcurrentOperationCount = 1
        theApiQ.qualityOfService = .background
//        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = endpointType
        
//        guard let destinationJcds2PackageInfo = destinationJcds2PackageInfo else {
//            return
//        }
        
        var destFilenameId = [String:[String:String]]()
        var pkgDisplayName = ""
        var objectId       = "0"
        var restMethod     = "POST"
//        if let destinationIndex = destinationJcds2PackageInfo.firstIndex(where: { $0.fileName == uploadFilename }) {
        //            pkgDisplayName = destinationJcds2PackageInfo[destinationIndex].displayName
        //            objectId       = "\(destinationJcds2PackageInfo[destinationIndex].id)"
        if let theIndex = destinationJcds2PackageInfo.firstIndex(where: { $0.fileName == uploadFilename }) {
            objectId       = "\(destinationJcds2PackageInfo[theIndex].id)"
            pkgDisplayName = destinationJcds2PackageInfo[theIndex].displayName

            // verify there is a record in Jamf Pro
            if Int(objectId) ?? 0 > 0 {
                restMethod     = "PUT"
//                print("[upload complete] package exists on destination: \(uploadFilename)")
//                print("[upload complete]          package display name: \(pkgDisplayName)")
//                print("[upload complete]                    package id: \(objectId)")
            } else {
                // package existed on JCDS but on Jamf Pro record
                objectId           = "0"
                if let sourceIndex = sourceJcds2PackageInfo.firstIndex(where: { $0.fileName == uploadFilename }) {
                    pkgDisplayName = sourceJcds2PackageInfo[sourceIndex].displayName
                }
            }
        } //else {
//            if let sourceIndex = sourceJcds2PackageInfo.firstIndex(where: { $0.fileName == uploadFilename }) {
//                pkgDisplayName = sourceJcds2PackageInfo[sourceIndex].displayName
//            }
//        }
//        if pkgDisplayName == "" {
//            pkgDisplayName = fullName
//        }
        if let sourceIndex = sourceJcds2PackageInfo.firstIndex(where: { $0.fileName == uploadFilename }) {
            pkgDisplayName = sourceJcds2PackageInfo[sourceIndex].displayName
        } else {
            pkgDisplayName = fullName
        }
        
//                let pkgDisplayName = (Parameters.cloudDistribitionPoint) ? Parameters.sourcePackagesDict["\(uploadFilename)"]?["name"]:"\(fullName)"
        let packageNotes = """
Upload date: \(getCurrentTime(theFormat: "info"))
Uploaded with: jamfCPR v\(AppInfo.version) authenticated with \(destinationUser)
Uploaded by: \(loggedInUser)
"""
        let xmlData = "<package><name>\(String(describing: pkgDisplayName))</name><filename>\(uploadFilename)</filename><notes>\(packageNotes)</notes><hash_value>0</hash_value></package>"
        WriteToLog.shared.message(stringOfText: "[ViewController.packageUpload] \(restMethod) note to package record: \(xmlData)")
    
    
        theApiQ.addOperation {
            
                    let packageName = uploadFilename

                    workingUrl = "\(server)/JSSResource/" + localEndPointType + "/id/\(objectId)"
                    workingUrl = workingUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                    WriteToLog.shared.message(stringOfText: "[ViewController.packageUpload] \(restMethod) to URL: \(workingUrl)")
                    
                    let encodedURL = URL(string: workingUrl)
                    let request = NSMutableURLRequest(url: encodedURL! as URL)
                    
                    request.httpMethod = restMethod
                    
                    let configuration = URLSessionConfiguration.default
        //            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
                    configuration.httpAdditionalHeaders = ["Authorization" : "\(String(describing: JamfProServer.authType["destination"]!)) \(String(describing: JamfProServer.accessToken["destination"]!))", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                    
                    let encodedXML = xmlData.data(using: String.Encoding.utf8)
                    request.httpBody = encodedXML!
                    
                    let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {
                        (data, response, error) -> Void in
                        session.finishTasksAndInvalidate()
                        if let httpResponse = response as? HTTPURLResponse {
                            //print(httpResponse.statusCode)
                            //print(httpResponse)
                            if let _ = String(data: data!, encoding: .utf8) {
                                responseData = String(data: data!, encoding: .utf8)!
                                if Int(objectId) ?? 0 > 0 {
                                    let newObjectId  = XmlDelegate().tagValue2(xmlString: responseData, startTag: "<id>", endTag: "</id>", includeTags: false)
                                    returnInfo["id"] = ( newObjectId == "" ) ? "-1":"\(newObjectId)"
                                } else {
                                    returnInfo["id"] = "\(objectId)"
                                }
                                returnInfo["filename"]    = "\(uploadFilename)"
                                returnInfo["displayName"] = "\(pkgDisplayName)"

                                //                        if self.debug { self.writeToLog(stringOfText: "[CreateEndpoints] \n\nfull response from create:\n\(responseData)") }
                                //                        print("create data response: \(responseData)")
                            } else {
                                WriteToLog.shared.message(stringOfText: "\n[updateXML] No data was returned from \(restMethod).")
                            }
                            returnInfo["statusCode"] = "\(httpResponse.statusCode)"
                            
                            if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                                Parameters.replicated.append(packageName)
                                WriteToLog.shared.message(stringOfText: "[updateXML] Successfully created record for package \(packageName).")
                                returnInfo["response"] = responseData
                                completion(returnInfo)
                            } else {
                                if httpResponse.statusCode == 409 {
                                    
                                    Parameters.replicated.append(packageName)
                                    WriteToLog.shared.message(stringOfText: "[updateXML] Package description for \(packageName) already exists and wasn't updated")
                                    returnInfo["response"] = "\(httpResponse.statusCode)"
                                } else {
                                    WriteToLog.shared.message(stringOfText: "[updateXML] ---------- status code ----------")
                                    WriteToLog.shared.message(stringOfText: "[updateXML] \(httpResponse.statusCode)")
                                    WriteToLog.shared.message(stringOfText: "[updateXML] ---------- response ----------")
                                    WriteToLog.shared.message(stringOfText: "[updateXML] \(httpResponse)")
                                    WriteToLog.shared.message(stringOfText: "[updateXML] ---------- response ----------")
                                    returnInfo["response"] = responseData
                                }
                                completion(returnInfo)
                            }
                            
                        } else {
                            returnInfo["id"]         = "-1"
                            returnInfo["response"]   = "no response to updateXML"
                            returnInfo["statusCode"] = "0000"
                            completion(returnInfo)
                        }

                    })  // let task = session.dataTask - end
                    task.resume()
//                    semaphore.wait()
//                } else {
//                    returnInfo["id"]         = "-1"
//                    returnInfo["response"]   = "failed token for updateXML"
//                    returnInfo["statusCode"] = "0000"
//                    completion(returnInfo)
//                }
//            }
            
            
        }   // theApiQ.addOperation - end
    }   // func create - end
    
    func action(serverUrl: String, endpoint: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String:Any]) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""

        switch endpoint {
        case  "jamf-pro-version":
            path = "v1/\(endpoint)"
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/uapi/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//uapi", with: "/uapi")
//        print("[ApiAction] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: url!)
        request.httpMethod = method

//        print("[ApiAction.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String:Any] {
                        WriteToLog.shared.message(stringOfText: "[ApiAction.action] Token retrieved from \(urlString).")
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        WriteToLog.shared.message(stringOfText: "[ApiAction.action] JSON error.")
                        completion([:])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message(stringOfText: "[ApiAction.action] Response error: \(httpResponse.statusCode).")
                    completion([:])
                    return
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[ApiAction.action] GET response error. Verify url and port.")
                completion([:])
                return
            }
        })
        task.resume()
            
    }   // func action - end
    
    func classic(whichServer: String, serverUrl: String, endpoint: String, method: String, completion: @escaping (_ returnedJSON: [String:Any]) -> Void) {
        
        var urlString = "\(serverUrl)/JSSResource/\(endpoint)"
        urlString     = urlString.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//        print("[classic] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: url!)
        request.httpMethod = method

        print("[classic] Attempting \(method) on \(urlString)")
        print("[classic] Bearer \(JamfProServer.accessToken[whichServer] ?? "")")
        
                URLCache.shared.removeAllCachedResponses()
                
                configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        print("[classic] httpResponse: \(httpResponse)")
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json! as? [String:Any] {
                                WriteToLog.shared.message(stringOfText: "[classic] Retrieved information from \(urlString).")
                                completion(endpointJSON)
                                return
                            } else {    // if let endpointJSON error
                                WriteToLog.shared.message(stringOfText: "[classic] JSON error.")
                                completion([:])
                                return
                            }
                        } else {    // if httpResponse.statusCode <200 or >299
                            WriteToLog.shared.message(stringOfText: "[classic] Response error: \(httpResponse.statusCode).")
                            completion([:])
                            return
                        }
                    } else {
                        WriteToLog.shared.message(stringOfText: "[classic] GET response error. Verify url and port.")
                        completion([:])
                        return
                    }
                })
                task.resume()
                
//            }
//        }
            
    }
    
    func getPackages(node: String, server: String, base64Creds: String = "", completion: @escaping (_ result: [String:[String:String]]) -> Void) {
    
        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] enter")

        URLCache.shared.removeAllCachedResponses()
        var endpointCount      = 0
        var packageIdNameDict  = [String:String]()
        var cloudPackageDict   = [String:[String:String]]()     //[package id: [package name: info]]
        var thePackageFileName = ""
        var pkgInfo            = [String:String]()
//        let getEndpointsQ  = OperationQueue() // create operation queue for API calls
        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Getting \(node)")
        
        let whichServer = ( server == JamfProServer.url["source"] ) ? "source":"destination"
                
        var myURL = "\(server)/JSSResource/\(node)"
        myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] URL: \(myURL)")
        
//        let semaphore         = DispatchSemaphore(value: 0)
        
//        getEndpointsQ.addOperation {
        
        let encodedURL = URL(string: myURL)
        let request = NSMutableURLRequest(url: encodedURL! as URL)
        request.httpMethod = "GET"
        let configuration = URLSessionConfiguration.ephemeral
        
                configuration.httpAdditionalHeaders = ["Authorization" : "\(String(describing: JamfProServer.authType[whichServer]!)) \(String(describing: JamfProServer.accessToken[whichServer]!))", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode > 199 && httpResponse.statusCode < 300 {
                                WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Getting all endpoints from: \(myURL)")
                                let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                if let endpointJSON = json as? [String: Any] {
                                    WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] endpointJSON: \(endpointJSON))")

                                    if let endpointInfo = endpointJSON["packages"] as? [Any] {
                                        endpointCount = endpointInfo.count
                                        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Count for \(node) on \(myURL): \(endpointCount)")

                                        if endpointCount > 0 {
                                            var completedLookUps = 0
        //                                    WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Found total of \(Parameters.packagesToReplicate.count) \(node) to process")
                                            
        //                                    print("Parameters.packagesToReplicate: \(String(describing: Parameters.packagesToReplicate))")
                                            
        //                                    print("[\(#function)] found \(endpointCount) packages on \(server) (\(whichServer))")
        //                                    print("[\(#function)] found \(sourceJcds2PackageInfo.count) packages on JCDS")
                                            for i in (0..<endpointCount) {
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                    if record["id"] != nil && record["name"] != nil {
                                                        
                                                        if ((Parameters.packagesToReplicate.firstIndex(of: "\(String(describing: record["id"]!))") != nil) && Parameters.searchScope != "all") || Parameters.searchScope == "all" {
                                                            if "\(String(describing: record["name"]!))" != "" {
                                                                packageIdNameDict["\(String(describing: record["id"]!))"] = "\(String(describing: record["name"]!))"
                                                                
        //                                                        cloudPackageDict["\(String(describing: record["id"]!))"] = ["name":"\(String(describing: record["name"]!))", "filename":""]
                                                                
                                                                WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] looking up: \(String(describing: record["name"]!))")
                                                                
                                                                self.endPointByID(endpoint: "packages/id/\(String(describing: record["id"]!))", endpointCurrent: i+1, endpointCount: endpointCount, server: server, base64Creds: base64Creds) {
                                                                    (returnedPackageInfo: (String,[String:String])) in
                                                                    (thePackageFileName, pkgInfo) = returnedPackageInfo
        //                                                            print("[\(#function)] \(whichServer) \(thePackageFileName) returnedPackageInfo: \(returnedPackageInfo)")
                                                                    if thePackageFileName != "" {
                                                                        Parameters.packagesDict[thePackageFileName] = pkgInfo
        //                                                                print("[getPackages] pkgInfo: \(pkgInfo)")
                                                                        
                                                                        // verify the package has a checksum (is present on the JCDS)
                                                                        if pkgInfo["checksum"] != "" || whichServer == "destination" {
        //                                                                    if whichServer == "source" {
        //                                                                        if let theIndex = sourceJcds2PackageInfo.firstIndex(where: { $0.fileName == thePackageFileName }) {
        //                                                                            sourceJcds2PackageInfo[theIndex].id          = Int(pkgInfo["id"]!.description) ?? -1
        //                                                                            sourceJcds2PackageInfo[theIndex].displayName = pkgInfo["name"] ?? "\(UUID())"
        //                                                                        }
        //                                                                    } else {
                                                                            
                                                                                if cloudPackageDict.count == 0 {
                                                                                    cloudPackageDict = [thePackageFileName:["id":"\(Int(pkgInfo["id"]!.description) ?? -1)", "displayName":pkgInfo["name"] ?? "\(UUID())"]]
                                                                                } else {
                                                                                    cloudPackageDict[thePackageFileName] = ["id":"\(Int(pkgInfo["id"]!.description) ?? -1)", "displayName":pkgInfo["name"] ?? "\(UUID())"]
                                                                                }
        //                                                                        if let theIndex = destinationJcds2PackageInfo.firstIndex(where: { $0.fileName == thePackageFileName }) {
        //                                                                            destinationJcds2PackageInfo[theIndex].id          = Int(pkgInfo["id"]!.description) ?? -1
        //                                                                            destinationJcds2PackageInfo[theIndex].displayName = pkgInfo["name"] ?? "\(UUID())"
        //                                                                            print("[getPackage] destination id of package \(thePackageFileName): \(destinationJcds2PackageInfo[theIndex].id )")
        //                                                                        }
        //                                                                    }
                                                                        } else {
                                                                            WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] \(thePackageFileName) is missing the checksum on the \(whichServer) server. The package is either missing on the JCDS or the checksum has not yet synced back to Jamf Pro.")
                                                                        }
                                                                    } else {
                                                                        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Found package record missing the filename in xml. Package id: \(String(describing: record["id"]!))")
                                                                        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] record: \(record)")
                                                                    }
                                                                    completedLookUps+=1
                //                                                  Parameters.message = "scanned \(completedLookUps) of \(endpointCount) packages"
                //
                                                                    if completedLookUps == endpointCount {
                                                                        if Parameters.debugValue {
                                                                            print("[ApiAction] [debug] Parameters.packagesDict: \(Parameters.packagesDict)")
                                                                        }
                                                                        completion(cloudPackageDict)
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            completedLookUps+=1
                                                            if completedLookUps == endpointCount {
                                                                if Parameters.debugValue {
                                                                    print("[ApiAction] [debug] Parameters.packagesDict: \(Parameters.packagesDict)")
                                                                }
                                                                completion(cloudPackageDict)
                                                            }
                                                        }
                                                    } else {
                                                        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Found package record missing the filename in xml, package id: \(record["id"] as? Int ?? -1)")
                                                        completedLookUps+=1
                                                        WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] record: \(record)")
        //                                              Parameters.message = "scanned \(completedLookUps) of \(endpointCount) packages"
        //
                                                        if completedLookUps == endpointCount {
                                                            if Parameters.debugValue {
                                                                print("[ApiAction] [debug] Parameters.packagesDict: \(Parameters.packagesDict)")
                                                            }
                                                            completion(cloudPackageDict)
                                                        }
                                                    }
                                                usleep(1000)  // sleep 0.001 seconds
                                            }   // for i in (0..<endpointCount) end
        //                                    destinationPackageInfo = destinationJcds2PackageInfo
                                        } else {
                                            completion(cloudPackageDict)
                                        }
                                        
                                    } else {   // end if let
                                        completion(cloudPackageDict)
                                    }
                                }   // if let endpointJSON - end
            //                        }

                        } else {
                            WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Error trying to get list of packages. Status code: \(httpResponse.statusCode)")
                            completion(cloudPackageDict)
                        }
                        
                    }   // if let httpResponse as? HTTPURLResponse - end
            //                semaphore.signal()
                    if error != nil {
                        print("[\(#function)] error: \(error?.localizedDescription ?? "unknown")")
                    }
                })  // let task = session - end
                task.resume()
        //        }   // theOpQ - end
        //        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
//            } else {
//                WriteToLog.shared.message(stringOfText: "[ApiAction.getPackages] Unable to get valid token.")
//                completion(cloudPackageDict)
//            }
//        }
        
    }
    
    // get full record in XML format
    func endPointByID(endpoint: String, endpointCurrent: Int, endpointCount: Int, server: String, base64Creds: String, completion: @escaping (_ returnedPackageInfo: (String,[String:String])) -> Void) {

        URLCache.shared.removeAllCachedResponses()
        WriteToLog.shared.message(stringOfText: "[endPointByID] endpoint passed to endPointByID: \(endpoint)")
        let getEndpointsQ  = OperationQueue() // create operation queue for API calls

        getEndpointsQ.maxConcurrentOperationCount = 4
        getEndpointsQ.qualityOfService = .background
//        let semaphore = DispatchSemaphore(value: 0)

        var myURL = "\(server)/JSSResource/\(endpoint)"
        myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
    
        getEndpointsQ.addOperation {
            var PostXML = ""
            WriteToLog.shared.message(stringOfText: "[endPointByID] fetching XML from: \(myURL)")

            let encodedURL = URL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
//            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            let whichServer = (server.fqdnFromUrl == JamfProServer.url["destination"]?.fqdnFromUrl) ? "destination":"source"
            
                    configuration.httpAdditionalHeaders = ["Authorization" : "\(String(describing: JamfProServer.authType[whichServer]!)) \(String(describing: JamfProServer.accessToken[whichServer]!))", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                    
                    let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {
                        (data, response, error) -> Void in
                        session.finishTasksAndInvalidate()
                        
                        if let _ = response as? HTTPURLResponse {
                            PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        //                    print("[endPointByID] PostXML: \(PostXML)")
                        } else {   // if let httpResponse - end
                            WriteToLog.shared.message(stringOfText: "[endPointByID] Issue communicating with the \(server).")
                            WriteToLog.shared.message(stringOfText: "[endPointByID] Response: \(String(describing: response as? HTTPURLResponse)).")
                        }
//                        WriteToLog.shared.message(stringOfText: "[endPointByID] PostXML \(PostXML).")   // remove this
                        completion((PostXML.package.filename,["name":PostXML.package.name, "filename":PostXML.package.filename, "id":PostXML.package.id, "size":PostXML.package.size, "checksum":PostXML.package.hash_value, "hashType":PostXML.package.hash_type]))
//                        semaphore.signal()
                        if error != nil {
                        }
                    })  // let task = session - end
                    //print("GET")
                    task.resume()
//                    semaphore.wait()
//                } else {
//                    WriteToLog.shared.message(stringOfText: "[endPointByID] Unable to get valid token.")
//                    completion(("",[:]))
//                }
//            }
            
            
        }   // getEndpointsQ - end
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

