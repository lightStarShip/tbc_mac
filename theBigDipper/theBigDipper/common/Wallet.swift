//
//  Wallet.swift
//  Pirate
//
//  Created by wesley on 2020/9/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SimpleLib
import SwiftyJSON

class Wallet:NSObject{
        
        private var Address:String?
        var SubAddress:String?
        var coreData:CDWallet?
        
        public static var WInst = Wallet()
        
        override init() {
                super.init()
                guard let core_data = PersistenceController.shared.findOneEntity(AppConstants.DBNAME_WALLET) as? CDWallet else{
                                return
                }
                
                guard let jsonStr = core_data.walletJSON, jsonStr != "" else {
                        return
                }
                
                guard LibLoadWallet(jsonStr.toGoString()) == 1 else {
                        NSLog("=======>[Wallet init] parse json failed[\(jsonStr)]")
                        return
                }

                self.Address = core_data.address
                self.SubAddress = core_data.subAddress
                coreData = core_data
                
                Stripe.SInst.loadCachedStripeInfoFromDB(walletAddr:self.SubAddress!)
        }
        
        public func initByJson(_ json:String){
                let jsonObj = JSON(parseJSON: json)
                self.Address = jsonObj["mainAddress"].string
                self.SubAddress = jsonObj["subAddress"].string
        }
        
        public static func NewInst(auth:String) -> Bool{
                guard let jsonData = LibNewWallet(auth.toGoString()) else{
                        return false
                }
                populateWallet(jsonStr: String(cString: jsonData))
                
                return true
        }
        
        private static func populateWallet(jsonStr:String){
                WInst.initByJson(jsonStr)
                
                var core_data = PersistenceController.shared.findOneEntity(AppConstants.DBNAME_WALLET) as? CDWallet
                if core_data == nil{
                        core_data = CDWallet(context: PersistenceController.shared.container.viewContext)
                }
                
                core_data!.walletJSON = jsonStr
                core_data!.address = WInst.Address
                core_data!.subAddress = WInst.SubAddress
                WInst.coreData = core_data
                PersistenceController.shared.saveContext()
                
                Stripe.SInst.loadCachedStripeInfoFromDB(walletAddr:WInst.SubAddress!)
        }
        
        public static func ImportWallet(auth:String, josn:String) -> Bool{
                guard LibImportWallet(josn.toGoString(), auth.toGoString()) == 1 else {
                        return false
                }
                populateWallet(jsonStr:josn)
                return true
        }
        
        public func IsOpen() -> Bool{
                return LibIsOpen() == 1
        }
        
        public func OpenWallet(auth:String) -> Bool{
                return LibOpenWallet(auth.toGoString()) == 1
        }
        
        public static func ParseAccountQRInmage(path:String)->String?{
                guard let data = ScanQrCode(path.toGoString()) else{
                        return nil
                }
                
                return String(cString: data)
        }
}
