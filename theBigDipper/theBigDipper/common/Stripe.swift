//
//  Stripe.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/12.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SimpleLib
import SwiftyJSON

class Stripe:NSObject{
        public static let queue = DispatchQueue.init(label: "Stripe Queue", qos: .utility)
        private let backendCheckoutUrl = URL(string: "loadStripeCustomerID")!
        
        var walletAddr:String?
        var customerID:String?
        var coreData:CDStripe?
        
        public static let SInst = Stripe()
        override init() {
                super.init()
        }
        
        func loadStripeInfoFromServer(walletAddr:String, callback:((Error?)->(Void))?=nil){Stripe.queue.async { [self] in
               
                guard let basicStr = LoadCustomerBasic(walletAddr.toGoString(), self.customerID?.toGoString() ?? "".toGoString()) else{
                        callback?(AppErr.stripe("LoadCustomerBasic failed".localized))
                        return
                }
                guard let e = updateInfoToDB(basicStr:String(cString: basicStr)) else{
                        callback?(nil)
                        return
                }
                
                callback?(e)
        }}
        
        private func updateInfoToDB(basicStr:String)->Error?{
                guard self.coreData != nil else {
                        return AppErr.stripe("should create cdstripe object first")
                }
                
                
                let json = JSON(parseJSON: basicStr)
                guard let cus_id = json["cus_id"].string,
                      let expire_day = json["expire_day"].int64,
                      let update_time = json["update_time"].int64 else{
                        return AppErr.stripe("parse basic stripe info failed")
                }
                self.coreData!.customerID = cus_id
                self.customerID = cus_id
                self.coreData!.expireDay = expire_day
                self.coreData!.updateTime = update_time
                PersistenceController.shared.saveContext()
                PostNoti(AppConstants.NOTI_STRIPE_USER_INFO_UPDATE)
                return nil
        }
        
        func getCoreData(walletAddr:String)->CDStripe{
                
                var core_data = PersistenceController.shared.findOneEntity(AppConstants.DBNAME_Stripe,
                                                              where: NSPredicate.init(format: "walletAddr=%@", walletAddr)) as? CDStripe
                if core_data == nil{
                        core_data = CDStripe(context: PersistenceController.shared.container.viewContext)
                        core_data!.walletAddr = walletAddr
                        PersistenceController.shared.saveContext()
                }
                return core_data!
        }
        
        
        func loadCachedStripeInfoFromDB(walletAddr:String){
                if self.coreData == nil{
                        self.coreData = getCoreData(walletAddr: walletAddr)
                }
                
                self.walletAddr = walletAddr
                self.customerID = self.coreData!.customerID
                
                loadStripeInfoFromServer(walletAddr: walletAddr){_ in
                        PostNoti(AppConstants.NOTI_NODE_LIST_UPDATE)
                }
                
                return
        }
        
        func getBalanceInDays()->Float{
                guard let expireDay = self.coreData?.expireDay else{
                        return 0.0
                }
                
                let balance = BalanceInDays(expireDay)
                return balance
        }
        
        func IsVipUser()->Bool{
                return getBalanceInDays() > 0.01
        }
        
        func transfer(to:String, days:Int, callback:((Error?)->(Void))?=nil){Stripe.queue.async { [self] in
                guard let err = TransferToFriend(self.customerID!.toGoString(), to.toGoString(), GoInt(days)) else{
                        callback?(nil)
                        return
                }
                callback?(AppErr.stripe(String(cString: err)))
        }}
}

class PayIntentParam:NSObject{
        
        var epherKey:String = ""
        var cliKey:String = ""
        var pubKey:String = ""
        var cusID:String = ""
        
        init?(jsonStr:String){
                super.init()
                let json = JSON(parseJSON: jsonStr)
                guard let cus_id = json["stripe_cus_id"].string,
                      let cli_key = json["payment_intent"].string,
                      let ehper_key = json["ephemeral_key"].string,
                      let pub_key = json["publishable_key"].string else{
                        return nil
                }
                self.cusID = cus_id
                self.cliKey = cli_key
                self.epherKey = ehper_key
                self.pubKey = pub_key
        }
}
