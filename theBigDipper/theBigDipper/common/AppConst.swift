//
//  AppConst.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation
public struct AppConstants {
        static public let DBNAME_RuleVer = "CDRuleVersion"
        static public let DBNAME_WALLET = "CDWallet"
        static public let DBNAME_APPSETTING = "CDAppSetting"
        static public let DBNAME_Stripe = "CDStripe"
        
        
        static public let ConfigUrl = "https://lightstarship.github.io"
        
        
        static public let NOTI_NODE_LIST_UPDATE = Notification.Name("NOTI_NODE_LIST_UPDATE")
        static public let NOTI_PRICE_LIST_UPDATE = Notification.Name("NOTI_NODE_LIST_UPDATE")
        static public let NOTI_STRIPE_USER_INFO_UPDATE = Notification.Name("NOTI_STRIPE_USER_INFO_UPDATE")
        
}
