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

class AppSetting:NSObject{
        
        static let PACServerPort = 31087;
        static let ProxyLocalPort = 31080;
        static let kDefaultPacURL = "http://127.0.0.1:\(PACServerPort)/proxy.pac";
        public static let systemProxyAuthRightName = "com.stars.tbd.mac-proxy"
        static var authRef: AuthorizationRef? = nil
        
        
#if DEBUG
        public static var StripeDebugMode:Int8 = 1
#else
        public static var StripeDebugMode:Int8 = 0
#endif
        
        static let rightDefaultRule: [String:Any] = [
         "key" : systemProxyAuthRightName,
         "class" : "user",
         "group" : "admin",
         "version" : 1 ]
        
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
                InitLib(AppSetting.StripeDebugMode,AppConstants.ConfigUrl.toGoString(), systemCallBack,uiLog)
                initPref()
                print("---------------->>>>")
        }
        
        static func callback(withJson:String){
                let json = JSON(parseJSON: withJson)
        }
        
        static func log(_ str:String){
                NSLog("\(str)")
        }
}
extension AppSetting{
        static func initPref(){
                let osStatus = AuthorizationCreate(nil, nil, [], &authRef)
                if osStatus != errAuthorizationSuccess{
                        NSLog(osStatus.description)
                        return;
                }
        }
        static func setupProxy(isGlobal:Bool, on:Bool){
                
                let rightName = AppSetting.systemProxyAuthRightName
                var currentRight:CFDictionary?
                var  status = AuthorizationRightGet((rightName as NSString).utf8String! , &currentRight)
                if (status == errAuthorizationDenied) {
                        status = AuthorizationRightSet(authRef!, (rightName as NSString).utf8String!, rightDefaultRule as CFDictionary, "Change system proxy settings." as CFString, nil, "Common" as CFString)
                        if (status != errAuthorizationSuccess) {
                                NSLog("AuthorizationRightSet failed")
                                return
                        }
                }
                
                var authItem = AuthorizationItem(name: (rightName as NSString).utf8String!, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
                var authRight: AuthorizationRights = AuthorizationRights(count: 1, items:&authItem)
                
                let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed ,.preAuthorize, .partialRights]
                let copyRightStatus = AuthorizationCopyRights(authRef!, &authRight, nil, authFlags, nil)
                
                Swift.print("AuthorizationCopyRights result: \(copyRightStatus), right name: \(rightName)")
                guard (copyRightStatus == errAuthorizationSuccess) else{
                        NSLog("grant authoriation failed")
                        return
                }
                
                guard let prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, "TheBigDipper" as CFString, nil, authRef)else{
                        NSLog("create preference failed")
                        return
                }
                
                guard let networkSets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) else{
                        NSLog("no valid netowrk service setting")
                        return
                }
                
                var proxySettings: [String:AnyObject] = [:]
                
                if on{
                        if isGlobal{
                                proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "127.0.0.1" as AnyObject
                                proxySettings[kCFNetworkProxiesSOCKSPort as String] = ProxyLocalPort as AnyObject
                                proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 1 as AnyObject
                        }else{
                                proxySettings[kCFNetworkProxiesProxyAutoConfigURLString as String] = kDefaultPacURL as AnyObject
                                proxySettings[kCFNetworkProxiesProxyAutoConfigEnable as String] = 1 as AnyObject
                        }
                        
                }else{
                        proxySettings[kCFNetworkProxiesProxyAutoConfigEnable as String] = 0 as AnyObject
                        proxySettings[kCFNetworkProxiesProxyAutoConfigURLString as String] = "" as AnyObject
                        
                        proxySettings[kCFNetworkProxiesHTTPEnable as String] = 0 as AnyObject
                        proxySettings[kCFNetworkProxiesHTTPSEnable as String] = 0 as AnyObject
                        
                        proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 0 as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "" as AnyObject
                        proxySettings[kCFNetworkProxiesSOCKSPort as String] = 0 as AnyObject
                        
                        proxySettings[kCFNetworkProxiesExceptionsList as String] = [] as AnyObject
                }
                
                
                proxySettings[kCFNetworkProxiesExceptionsList as String] = [
                        "192.168.0.0/16",
                        "10.0.0.0/8",
                        "172.16.0.0/12",
                        "127.0.0.1",
                        "localhost",
                        "*.local"
                ] as AnyObject
                
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
