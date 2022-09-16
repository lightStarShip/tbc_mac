//
//  AppConst.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation

public struct AppConstants {
        static public let CMD_LINE_VER = "1.0.6"
        static public let DBNAME_RuleVer = "CDRuleVersion"
        static public let DBNAME_WALLET = "CDWallet"
        static public let DBNAME_APPSETTING = "CDAppSetting"
        static public let DBNAME_Stripe = "CDStripe"
        static public let SERVICE_NME_FOR_OSS = "com.star.thebigdipper"
        static public let ProxyLocalPort = 31080;
        static public let CmdLineProxy = "export https_proxy=socks5://127.0.0.1:\(ProxyLocalPort);http_proxy=socks5://127.0.0.1:\(ProxyLocalPort)"
        
        
        static public let ConfigUrl = "https://lightstarship.github.io"
        static public let WebSite = "https://stars.simplenets.org./"
        
        static public let NOTI_NODE_LIST_UPDATE = Notification.Name("NOTI_NODE_LIST_UPDATE")
        static public let NOTI_PRICE_LIST_UPDATE = Notification.Name("NOTI_NODE_LIST_UPDATE")
        static public let NOTI_STRIPE_USER_INFO_UPDATE = Notification.Name("NOTI_STRIPE_USER_INFO_UPDATE")
        
}
