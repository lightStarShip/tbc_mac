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

        
#if DEBUG
        public static var StripeDebugMode:Int8 = 1
#else
        public static var StripeDebugMode:Int8 = 0
#endif
        
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
                setupProxy(isGlobal: false, on: true)
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
        
        static func setupProxy(isGlobal:Bool, on:Bool){
                
                var authRef: AuthorizationRef? = nil
                let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed ,.preAuthorize]
                let osStatus = AuthorizationCreate(nil, nil, authFlags, &authRef)
                if osStatus != errAuthorizationSuccess{
                        NSLog(osStatus.description)
                        return;
                }
                
                if authRef == nil{
                        NSLog("grant authoriation failed")
                        return
                }
                
                guard let prefRef = SCPreferencesCreateWithAuthorization(nil, "TheBigDipper" as CFString, nil, authRef)else{
                        NSLog("create preference failed")
                        return
                }
                
                guard let networkSets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) else{
                        NSLog("no valid netowrk service setting")
                        return
                }
                
                for key in networkSets.allKeys {
                        let dict = networkSets.object(forKey: key) as? NSDictionary
                        let hardware = ((dict?["Interface"]) as? NSDictionary)?["Hardware"] as? String
                        if hardware != "AirPort" && hardware != "Ethernet" && hardware != "Wi-Fi"{
                                continue
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
                        
                        
                        let path = "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)"
                        SCPreferencesPathSetValue(prefRef, path as CFString, proxySettings as CFDictionary)
                }
                
                let commitRet = SCPreferencesCommitChanges(prefRef)
                let applyRet = SCPreferencesApplyChanges(prefRef)
                SCPreferencesSynchronize(prefRef)
                
                AuthorizationFree(authRef!, AuthorizationFlags())
                
                NSLog("System proxy set result commitRet=\(commitRet), applyRet=\(applyRet)");
        }

}
