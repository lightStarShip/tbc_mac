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
        
        //        static let PACServerPort = 31087;
        static let ProxyLocalPort = 31080;
        //        static let kDefaultPacURL = "http://127.0.0.1:\(PACServerPort)/proxy.pac";
        public static let systemProxyAuthRightName = "com.stars.tbd.mac-proxy_v7"
        static var authRef: AuthorizationRef? = nil
        
        //        static let authorization = SFAuthorization.authorization() as! SFAuthorization
        
        static var coreData:CDAppSetting?
        
#if DEBUG
        public static var StripeDebugMode:Int8 = 1
#else
        public static var StripeDebugMode:Int8 = 0
#endif
        
        static let rightDefaultRule: [String:Any] = [
                "key" : systemProxyAuthRightName,
                "class" : "user",
                "group" : "admin",
                "version" : 1 ,
                "timeout": 0]
        
        
        enum LogLevel:Int8{
                case debug = 0
                case info = 1
                case warn = 2
                case error = 3
        }
        
        
        public static let workQueue = DispatchQueue.init(label: "APP Work Queue", qos: .utility)
        
        static var systemCallBack:UserInterfaceAPI = {v in
                guard let data = v else{
                        return
                }
                callback(withJson: String(cString: data))
        }
        
        static var uiLog:CallBackLog = {v in
                guard let data = v else{
                        return
                }
                log(String(cString: data))
        }
        
        static func initSettting(){
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
                
                
                RuleManager.rInst.loadRulsByVersion()
                
                if let err = initAuthorization(){
                        print("------>>>", err.localizedDescription)
                }
                
        }
        
        static func callback(withJson:String){
                //                let json = JSON(parseJSON: withJson)
        }
        
        static func log(_ str:String){
                NSLog("\(str)")
        }
        
        
        static func setupProxy(on:Bool) -> Error?{
                
                setupProxySetting(on:on)
                
                if on{
                        guard Wallet.WInst.SubAddress != nil else{
                                return AppErr.wallet("import wallet please".localized)
                        }
                        
                        let proxyAddr = "127.0.0.1:\(ProxyLocalPort)".toGoString()
                        let node_addr = AppSetting.coreData?.minerAddrInUsed
                        guard let node = NodeItem.GetNode(addr:node_addr) else{
                                return AppErr.conf("no valid node")
                        }
                        
                        let ip = node.ipStr.toGoString()
                        let addr = node.wallet.toGoString()
                        let rule = RuleManager.rInst.domainStr().toGoString()
                        if let err = StartProxy(proxyAddr, ip, addr, rule){
                                return AppErr.lib(String(cString: err))
                        }
                        
                }else{
                        StopProxy()
                }
                
                return nil
        }
        
        static func proxyIsOn() -> Bool{
                return ProxyStatus() == 1
        }
}


extension AppSetting{
        
        static func initAuthorization() -> Error?{
                var status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)
                if status != errAuthorizationSuccess{
                        return AppErr.system("create authRef failed")
                }
                
                
                let rightName = AppSetting.systemProxyAuthRightName
                var currentRight:CFDictionary?
                status = AuthorizationRightGet((rightName as NSString).utf8String! , &currentRight)
                if (status == errAuthorizationDenied) {
                        status = AuthorizationRightSet(authRef!, (rightName as NSString).utf8String!, rightDefaultRule as CFDictionary, "Change system proxy settings." as CFString, nil, "Common" as CFString)
                        if (status != errAuthorizationSuccess) {
                                return AppErr.system("AuthorizationRightSet failed")
                        }
                }
                
                var authItem = AuthorizationItem(name: (rightName as NSString).utf8String!,
                                                 valueLength: 0,
                                                 value:UnsafeMutableRawPointer(bitPattern: 0),
                                                 flags: 0)
                var authRights = AuthorizationRights(count:1, items: withUnsafeMutablePointer(to:&authItem){
                        p in
                        return p
                })
                
                let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed, .preAuthorize, .partialRights]
                status = AuthorizationCopyRights(authRef!, &authRights, nil,authFlags, nil);
                if (status == errAuthorizationSuccess) {
                        return AppErr.system("AuthorizationCopyRights failed")
                }
                return nil
                
        }
        
        static func setupProxySetting(on:Bool){
                
                guard let prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, "TheBigDipper" as CFString, nil, authRef!)else{
                        NSLog("create preference failed")
                        return
                }
                
                guard let networkSets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) else{
                        NSLog("no valid netowrk service setting")
                        return
                }
                
                var proxySettings: [String:AnyObject] = [:]
                
                if on{
                        proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "127.0.0.1" as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSPort as String] = ProxyLocalPort as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 1 as AnyObject
                        proxySettings[kCFNetworkProxiesExceptionsList as String] = [
                                "192.168.0.0/16",
                                "10.0.0.0/8",
                                "172.16.0.0/12",
                                "127.0.0.1",
                                "localhost",
                                "*.local"
                        ] as AnyObject
                        
                }else{
                        proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 0 as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "" as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSPort as String] = 0 as AnyObject
                        proxySettings[kCFNetworkProxiesExceptionsList as String] = [] as AnyObject
                }
                
                
                for key in networkSets.allKeys {
                        let dict = networkSets.object(forKey: key) as? NSDictionary
                        let hardware = ((dict?["Interface"]) as? NSDictionary)?["Hardware"] as? String
                        if hardware != "AirPort" && hardware != "Ethernet" && hardware != "Wi-Fi"{
                                continue
                        }
                        
                        
                        let path = "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)"
                        SCPreferencesPathSetValue(prefRef, path as CFString, proxySettings as CFDictionary)
                }
                
                let commitRet = SCPreferencesCommitChanges(prefRef)
                let applyRet = SCPreferencesApplyChanges(prefRef)
                SCPreferencesSynchronize(prefRef)
                
                //                AuthorizationFree(authRef!, AuthorizationFlags())
                
                NSLog("System proxy set result commitRet=\(commitRet), applyRet=\(applyRet)");
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