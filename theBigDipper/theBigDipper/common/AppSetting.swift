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

class AppSetting:NSObject{
        
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
                
                try  ensureLaunchAgentsDirOwner()
                
                SysProxyHelper.install()
                
        }
        
        static func callback(withJson:String){
                let json = JSON(parseJSON: withJson)
        }
        
        static func log(_ str:String){
                NSLog("\(str)")
        }
}

extension AppSetting{
        
        func ensureLaunchAgentsDirOwner () throws{
                let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
                let fileMgr = FileManager.default
                if !fileMgr.fileExists(atPath: dirPath) {
                    exit(-1)
                }
                
                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)
                if attrs[FileAttributeKey.ownerAccountName] as! String != NSUserName() {
                        let bashFilePath = Bundle.main.path(forResource: "fix_dir_owner.sh", ofType: nil)!
                        let script = "do shell script \"bash \\\"\(bashFilePath)\\\" \(NSUserName()) \" with administrator privileges"
                        if let appleScript = NSAppleScript(source: script) {
                                var err: NSDictionary? = nil
                                appleScript.executeAndReturnError(&err)
                        }
                }
        }

}
