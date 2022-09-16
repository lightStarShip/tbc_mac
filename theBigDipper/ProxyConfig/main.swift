//
//  main.swift
//  ProxyConfig
//
//  Created by wesley on 2022/9/5.
//

import Foundation
import SystemConfiguration

if CommandLine.argc != 2{
        print("------>>> invalid args")
        exit(1)
}


let argument = CommandLine.arguments[1]
if (strncmp(argument, "version", strlen("version")) == 0) {
        print(AppConstants.CMD_LINE_VER);
        exit(EXIT_SUCCESS);
}else if  (strncmp(argument, "start", strlen("start")) == 0){
        if let e = setupProxy(on:true){
                print(e.localizedDescription)
                exit(EXIT_FAILURE);
        }
        exit(EXIT_SUCCESS);
}else{
        if let e = setupProxy(on:false){
                print(e.localizedDescription)
                exit(EXIT_FAILURE);
        }
        exit(EXIT_SUCCESS);
}

func setupProxy(on:Bool) ->Error?{
        
        var authRef: AuthorizationRef? = nil
        let authFlags:AuthorizationFlags = [.extendRights , .interactionAllowed, .preAuthorize, .partialRights]
        let authErr = AuthorizationCreate(nil, nil, authFlags, &authRef);
        if (authErr != noErr) {
                authRef = nil;
                return AppErr.proxySet("Error when create authorization");
        }
        if (authRef == nil) {
                return AppErr.proxySet("No authorization has been granted to modify network configuration");
        }
        
        guard let prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, "TheBigDipper" as CFString, nil, authRef!)else{
                return AppErr.proxySet("create preference failed")
        }
        
        guard let networkSets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) else{
                return AppErr.proxySet("no valid netowrk service setting")
        }
        
        var proxySettings: [String:AnyObject] = [:]
        
        if on{
                proxySettings[kCFNetworkProxiesSOCKSProxy as String] = "0.0.0.0" as AnyObject
                proxySettings[kCFNetworkProxiesSOCKSPort as String] = AppConstants.ProxyLocalPort as AnyObject
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
        AuthorizationFree(authRef!, authFlags)
        
        if commitRet && applyRet{
                return nil
        }
        
        return AppErr.proxySet("apply proxy failed")
}
