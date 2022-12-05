//
//  AppSetting.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation
import CoreData
import SimpleLib
import SwiftyJSON
import SystemConfiguration
import SecurityInterface

class AppSetting:NSObject{
        static public var APP_VER: String {
                guard let ver =  Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String  else{
                        return ""
                }
                return "\(ver).\(build)"
        }
        
        static let kProxyConfigPath = "/Library/Application Support/TheBigDipper/ProxyConfig"
        
        static var coreData:CDAppSetting?
        
#if DEBUG
        public static var StripeDebugMode:Int8 = 1
#else
        public static var StripeDebugMode:Int8 = 0
#endif
        
        enum LogLevel:Int8{
                case debug = 0
                case info = 1
                case warn = 2
                case error = 3
        }
        enum CmdType:Int8{
                case nop = 0
                case LoadDns = 1
                case LoadInnerIP = 2
        }
        
        
        public static let workQueue = DispatchQueue.init(label: "APP Work Queue", qos: .utility)
        
        static var systemCallBack:UserInterfaceAPI = {v in
                guard let data = v else{
                        return  "".toCString()
                }
                return callback(withJson: String(cString: data)).toCString()
        }
        
        static var uiLog:CallBackLog = {v in
                guard let data = v else{
                        return
                }
                log(String(cString: data))
        }
        
        @objc func cleanup(_ aNotification: Notification){
                _ = AppSetting.setupProxySetting(on: false)
        }
        
        static func preOSShutDown(){
                
                NSWorkspace.shared.notificationCenter.addObserver(self,
                                                                  selector: #selector(cleanup(_:)),
                                                                  name: NSWorkspace.willPowerOffNotification,
                                                                  object: nil)
                
                let handler: @convention(c) (Int32) -> () = { sig in
                        _ = AppSetting.setupProxySetting(on: false)
                        exit(0)
                }
                var action = sigaction(__sigaction_u: unsafeBitCast(handler, to: __sigaction_u.self),
                                       sa_mask: 0,
                                       sa_flags: 0)
                
                sigaction(SIGKILL, &action, nil)
                sigaction(SIGTERM, &action, nil)
                sigaction(SIGQUIT, &action, nil)
        }
        
        static func initSettting(){
                
                preOSShutDown()
                
                ensureLaunchAgentsDirOwner()
                
                print("------>>>debug:", AppSetting.StripeDebugMode)
                
                InitLib(AppSetting.StripeDebugMode,
                        LogLevel.debug.rawValue,
                        AppConstants.ConfigUrl.toGoString(),
                        systemCallBack,
                        uiLog)
                
                var setting = PersistenceController.shared.findOneEntity(AppConstants.DBNAME_APPSETTING) as? CDAppSetting
                if setting == nil{
                        setting = CDAppSetting(context: PersistenceController.shared.container.viewContext)
                        setting!.minerAddrInUsed = nil
                        setting!.stream = true
                        
                        PersistenceController.shared.saveContext()
                }
                
                AppSetting.coreData = setting
                
                if let subAddr = Wallet.WInst.SubAddress {
                        var pwd = AppSetting.readPassword(service: AppConstants.SERVICE_NME_FOR_OSS,
                                                          account: subAddr)
                        if pwd == nil{
                                pwd = showPasswordDialog()
                        }
                        
                        if !Wallet.WInst.OpenWallet(auth: pwd!){
                                dialogOK(question: "Error".localized, text: "open local account failed".localized)
                                return
                        }
                }
                
                RuleManager.rInst.loadRulsByVersion()
                
                if !install(){
                        print("------>>> failed")
                }
        }
        
        static func callback(withJson:String)->String{
                
                let json = JSON(parseJSON: withJson)
                let cmd = json["cmd"].int8 ?? -1
                
                
                switch cmd{
                case CmdType.LoadDns.rawValue:
                        return RuleManager.rInst.domainStr()
                case CmdType.LoadInnerIP.rawValue:
                        return RuleManager.rInst.innerIPStr()
                default:
                        return ""
                }
        }
        
        static func log(_ str:String){
                NSLog("\(str)")
        }
        
        
        static func setupProxy(on:Bool) -> Error?{
                
                if on{
                        let proxyAddr = "0.0.0.0:\(AppConstants.ProxyLocalPort)".toGoString()
                        let node_addr = AppSetting.coreData?.minerAddrInUsed
                        guard let node = NodeItem.GetNode(addr:node_addr) else{
                                return AppErr.conf("no valid node")
                        }
                        if node_addr == nil{
                                AppSetting.coreData?.minerAddrInUsed = node.wallet
                        }
                        
                        let nodeIP = node.ipStr.toGoString()
                        let walletArr = node.wallet.toGoString()
                        if let err = StartProxy(proxyAddr, nodeIP, walletArr){
                                return AppErr.lib(String(cString: err))
                        }
                        
                }else{
                        StopProxy()
                }
                
                if let e = setupProxySetting(on:on){
                        return e
                }
                
                return nil
        }
        
        static func proxyIsOn() -> Bool{
                return ProxyStatus() == 1
        }
}


extension AppSetting{
        
        static func save(password: String, service: String, account: String) ->Bool {
                
                let pData = password.data(using: .utf8)
                let query: [String: AnyObject] = [
                        // kSecAttrService,  kSecAttrAccount, and kSecClass
                        // uniquely identify the item to save in Keychain
                        kSecAttrService as String: service as AnyObject,
                        kSecAttrAccount as String: account as AnyObject,
                        kSecClass as String: kSecClassGenericPassword,
                        
                        // kSecValueData is the item value to save
                        kSecValueData as String: pData as AnyObject
                ]
                
                // SecItemAdd attempts to add the item identified by
                // the query to keychain
                let status = SecItemAdd(
                        query as CFDictionary,
                        nil
                )
                
                
                // Any status other than errSecSuccess indicates the
                // save operation failed.
                guard status == errSecSuccess else {
                        print("------>>> oss save failed :=>", status)
                        return false
                }
                return true
        }
        
        static func readPassword(service: String, account: String) -> String? {
                let query: [String: AnyObject] = [
                        // kSecAttrService,  kSecAttrAccount, and kSecClass
                        // uniquely identify the item to read in Keychain
                        kSecAttrService as String: service as AnyObject,
                        kSecAttrAccount as String: account as AnyObject,
                        kSecClass as String: kSecClassGenericPassword,
                        
                        // kSecMatchLimitOne indicates keychain should read
                        // only the most recent item matching this query
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        
                        // kSecReturnData is set to kCFBooleanTrue in order
                        // to retrieve the data for the item
                        kSecReturnData as String: kCFBooleanTrue
                ]
                
                // SecItemCopyMatching will attempt to copy the item
                // identified by query to the reference itemCopy
                var itemCopy: AnyObject?
                let status = SecItemCopyMatching(
                        query as CFDictionary,
                        &itemCopy
                )
                
                // errSecItemNotFound is a special status indicating the
                // read item does not exist. Throw itemNotFound so the
                // client can determine whether or not to handle
                // this case
                guard status != errSecItemNotFound else {
                        print("------>>> oss read failed :=>", status)
                        return nil
                }
                
                guard status == errSecSuccess else {
                        print("------>>> oss read failed :=>", status)
                        return nil
                }
                
                // This implementation of KeychainInterface requires all
                // items to be saved and read as Data. Otherwise,
                // invalidItemFormat is thrown
                guard let password = itemCopy as? Data else {
                        print("------>>> oss read failed :=>", itemCopy as Any)
                        return nil
                }
                return String(data: password, encoding: .utf8)
        }
}


extension AppSetting{
        
        static func ensureLaunchAgentsDirOwner () {
                let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
                let fileMgr = FileManager.default
                if fileMgr.fileExists(atPath: dirPath) {
                        do {
                                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)
                                if attrs[FileAttributeKey.ownerAccountName] as! String != NSUserName() {
                                        //try fileMgr.setAttributes([FileAttributeKey.ownerAccountName: NSUserName()], ofItemAtPath: dirPath)
                                        let bashFilePath = Bundle.main.path(forResource: "fix_dir_owner.sh", ofType: nil)!
                                        let script = "do shell script \"bash \\\"\(bashFilePath)\\\" \(NSUserName()) \" with administrator privileges"
                                        if let appleScript = NSAppleScript(source: script) {
                                                var err: NSDictionary? = nil
                                                appleScript.executeAndReturnError(&err)
                                        }
                                }
                        }
                        catch {
                                NSLog("Error when ensure the owner of $HOME/Library/LaunchAgents, \(error.localizedDescription)")
                        }
                }
        }
        public static func checkVersion() -> Bool {
                let task = Process()
                task.launchPath = kProxyConfigPath
                task.arguments = ["version"]
                
                let pipe = Pipe()
                task.standardOutput = pipe
                let fd = pipe.fileHandleForReading
                task.launch()
                
                task.waitUntilExit()
                
                if task.terminationStatus != 0 {
                        return false
                }
                
                let res = String(data: fd.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
                if res.contains(AppConstants.CMD_LINE_VER) {
                        return true
                }
                return false
        }
        static func setupProxySetting(on:Bool)->Error?{
                
                if !FileManager.default.fileExists(atPath: kProxyConfigPath){
                        if on{
                                return AppErr.conf("lost proxy setting cmd")
                        }
                        return nil
                }
                
                let task = Process()
                task.launchPath = kProxyConfigPath
                var arg = ""
                if on{
                        arg = "start"
                }else{
                        arg = "stop"
                }
                task.arguments = [arg]
                
                let pipe = Pipe()
                task.standardOutput = pipe
                let fd = pipe.fileHandleForReading
                task.launch()
                
                task.waitUntilExit()
                
                if task.terminationStatus != 0 {
                        let res = String(data: fd.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
                        return AppErr.conf(res)
                }
                
                return nil
        }
        
        public static func install() -> Bool {
                
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: kProxyConfigPath) || !checkVersion() {
                        
                        let scriptPath = "\(Bundle.main.resourcePath!)/install_proxy_helper.sh"
                        
                        let myAppleScript = """
                                        do shell script \"/bin/bash \\\"\(scriptPath)\\\"\" with administrator privileges
                                """
                        let appleScript = NSAppleScript(source: myAppleScript)
                        var dict: NSDictionary?
                        let _ = appleScript?.executeAndReturnError(&dict)
                        return dict == nil
                }
                return true
        }
}
