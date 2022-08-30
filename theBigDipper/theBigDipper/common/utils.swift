//
//  utils.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation
import SimpleLib
import SystemConfiguration

extension String {
        var localized: String {
                return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
        func format(parameters: CVarArg...) -> String {
                return String(format: self, arguments: parameters)
        }
        
        func toGoString() ->GoString {
                let cs = (self as NSString).utf8String
                let buffer = UnsafePointer<Int8>(cs!)
                return GoString(p:buffer, n:strlen(buffer))
        }
}



func SetupSystemProxy(isGlobal:Bool, setup:Bool)->Error?{
        var authRef: AuthorizationRef? = nil
        let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed ,.preAuthorize]
        let osStatus = AuthorizationCreate(nil, nil, authFlags, &authRef)
        if osStatus != errAuthorizationSuccess{
                return AppErr.system(osStatus.description)
        }
        
        if authRef == nil{
                return AppErr.system("grant authoriation failed")
        }
        
        guard let prefRef = SCPreferencesCreateWithAuthorization(nil, "TheBigDipper" as CFString, nil, authRef)else{
                return AppErr.system("create preference failed")
        }
        
        guard let networkSets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) else{
                return AppErr.system("no valid netowrk service setting")
        }
        
        for key in networkSets.allKeys {
                let dict = networkSets.object(forKey: key) as? NSDictionary
                let hardware = ((dict?["Interface"]) as? NSDictionary)?["Hardware"] as? String
                if hardware != "AirPort" && hardware != "Ethernet" && hardware != "Wi-Fi"{
                        continue
                }
                
                var proxySettings: [String:AnyObject] = [:]
                
                if setup{
                        
                        if isGlobal{
                                
                                proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "127.0.0.1" as AnyObject
                                proxySettings[kCFNetworkProxiesSOCKSPort as String] = AppConstants.ProxyLocalPort as AnyObject
                                proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 1 as AnyObject
                        }else{
                                proxySettings[kCFNetworkProxiesProxyAutoConfigURLString as String] = AppConstants.kDefaultPacURL as AnyObject
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
        
        SCPreferencesCommitChanges(prefRef)
        SCPreferencesApplyChanges(prefRef)
        return nil
}
