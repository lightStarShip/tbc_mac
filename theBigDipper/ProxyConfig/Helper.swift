//
//  Helper.swift
//  MyApplication
//
//  Created by Erik Berglund on 2016-12-06.
//  Copyright © 2016 Erik Berglund. All rights reserved.
//

import Foundation
import SystemConfiguration

class Helper: NSObject, HelperProtocol, NSXPCListenerDelegate{
    
    private var connections = [NSXPCConnection]()
    private var listener:NSXPCListener
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0
        static let PACServerPort = 31087;
        static let ProxyLocalPort = 31080;
        static let kDefaultPacURL = "http://127.0.0.1:\(PACServerPort)/proxy.pac";
        
    override init(){
        self.listener = NSXPCListener(machServiceName:HelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }
    
    /* 
        Starts the helper tool
     */
    func run(){
        self.listener.resume()
        
        // Kepp the helper running until shouldQuit variable is set to true.
        // This variable is changed to true in the connection invalidation handler in the listener(_ listener:shoudlAcceptNewConnection:) funciton.
        while !shouldQuit {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: shouldQuitCheckInterval))
        }
    }
    
    /*
        Called when the application connects to the helper
     */
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool
    {
        
        // MARK: Here a check should be added to verify the application that is calling the helper
        // For example, checking that the codesigning is equal on the calling binary as this helper.
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProcessProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with:HelperProtocol.self)
        newConnection.exportedObject = self;
        newConnection.invalidationHandler = (() -> Void)? {
            if let indexValue = self.connections.index(of: newConnection) {
                self.connections.remove(at: indexValue)
            }
            
            if self.connections.count == 0 {
                self.shouldQuit = true
            }
        }
        self.connections.append(newConnection)
        newConnection.resume()
        return true
    }
    
    /*
        Return bundle version for this helper
     */
    func getVersion(reply: @escaping (String) -> Void) {
        reply(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)
    }
    
    /*
        Functions to run from the main app
     */
  
    func startConfirmedProxy(reply: @escaping (NSNumber) -> Void) {
        
        // For security reasons, all commands should be hardcoded in the helper
        //we should probably iterate through all interfaces?
        let command = "/usr/sbin/networksetup"
        var arguments = ["-setwebproxy", "wi-fi", "127.0.0.1", "9090"]
        runTask(command: command, arguments: arguments, reply:reply)
        
        arguments = ["-setsecurewebproxy", "wi-fi", "127.0.0.1", "9090"]
        runTask(command: command, arguments: arguments, reply:reply)
        
        
        arguments = ["-setwebproxystate", "wi-fi", "on"]
        runTask(command: command, arguments: arguments, reply:reply)
        
        arguments = ["-setsecurewebproxystate", "wi-fi", "on"]
        runTask(command: command, arguments: arguments, reply:reply)
    }
    
    func stopConfirmedProxy(reply: @escaping (NSNumber) -> Void) {
        
        // For security reasons, all commands should be hardcoded in the helper
        let command = "/usr/sbin/networksetup"
        var arguments = ["-setwebproxystate", "wi-fi", "off"]
        
        // Run the task
        runTask(command: command, arguments: arguments, reply:reply)
        
        arguments = ["-setsecurewebproxystate", "wi-fi", "off"]
        runTask(command: command, arguments: arguments, reply:reply)
    }
    
    /*
        Not really used in this test app, but there might be reasons to support multiple simultaneous connections.
     */
    private func connection() -> NSXPCConnection
    {
        return self.connections.last!
    }
    
    
    /*
        General private function to run an external command
     */
    private func runTask(command: String, arguments: Array<String>, reply:@escaping ((NSNumber) -> Void)) -> Void
    {
        let task:Process = Process()
        let stdOut:Pipe = Pipe()
        
        let stdOutHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection().remoteObjectProxy as? ProcessProtocol {
                //remoteObject.log(stdOut: output as String)
            }
        }
        stdOut.fileHandleForReading.readabilityHandler = stdOutHandler
        
        let stdErr:Pipe = Pipe()
        let stdErrHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection().remoteObjectProxy as? ProcessProtocol {
                //remoteObject.log(stdErr: output as String)
            }
        }
        stdErr.fileHandleForReading.readabilityHandler = stdErrHandler
        
        task.launchPath = command
        task.arguments = arguments
        task.standardOutput = stdOut
        task.standardError = stdErr
        
        task.terminationHandler = { task in
            reply(NSNumber(value: task.terminationStatus))
        }
        
        task.launch()
    }
        
        
        func setupProxy(isGlobal:Bool, on:Bool){
                
                guard let prefRef = SCPreferencesCreate(kCFAllocatorDefault, "TheBigDipper" as CFString, nil)else{
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
                                proxySettings[kCFNetworkProxiesSOCKSPort as String] = Helper.ProxyLocalPort as AnyObject
                                proxySettings[kCFNetworkProxiesSOCKSEnable as String] = 1 as AnyObject
                        }else{
                                proxySettings[kCFNetworkProxiesProxyAutoConfigURLString as String] = Helper.kDefaultPacURL as AnyObject
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
                
                NSLog("System proxy set result commitRet=\(commitRet), applyRet=\(applyRet)");
        }
        
}
