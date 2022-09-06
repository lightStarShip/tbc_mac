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
        public static let systemProxyAuthRightName = "com.stars.tbd.mac-proxy_v4"
        //        static var authRef: AuthorizationRef? = nil
        
        static let authorization = SFAuthorization.authorization() as! SFAuthorization
        
        static var coreData:CDAppSetting?
        
#if DEBUG
        public static var StripeDebugMode:Int8 = 1
#else
        public static var StripeDebugMode:Int8 = 0
#endif
        
        static let rightDefaultRule: [String:Any] = [
                "key" : systemProxyAuthRightName,
                
                "allow-root": false,
                "authenticate-user": true,
                "class": "user",
                "session-owner": true,
                "shared": false,
                "timeout": 0
        ]

        
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
                        "".toGoString(),
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
                
                initAuthorization()
                
                print("---------------->>>>")
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
                        if let err = StartProxy("127.0.0.1:\(ProxyLocalPort)".toGoString()){
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
        
        static func initAuthorization(){
                
                let rightName = AppSetting.systemProxyAuthRightName
                var currentRight:CFDictionary?
                var  status = AuthorizationRightGet((rightName as NSString).utf8String! , &currentRight)
                if (status == errAuthorizationDenied) {
                        status = AuthorizationRightSet(authorization.authorizationRef()!, (rightName as NSString).utf8String!, rightDefaultRule as CFDictionary, "Change system proxy settings." as CFString, nil, "Common" as CFString)
                        if (status != errAuthorizationSuccess) {
                                NSLog("AuthorizationRightSet failed")
                                return
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
                
                do{
                        let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed ,.preAuthorize, .partialRights]
                        try authorization.obtain(withRights: &authRights, flags: authFlags, environment: nil,authorizedRights: nil)
                }catch let err{
                        NSLog(err.localizedDescription)
                }
        }
        static func setupProxySetting(on:Bool){
                
                guard let prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, "TheBigDipper" as CFString, nil, authorization.authorizationRef()!)else{
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
