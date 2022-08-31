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
                
//                try  ensureLaunchAgentsDirOwner()
                
                SysProxyHelper.install()
                SysProxyHelper.SetupProxy(isGlocal: false)
                
        }
        
        static func callback(withJson:String){
                let json = JSON(parseJSON: withJson)
        }
        
        static func log(_ str:String){
                NSLog("\(str)")
        }
}
