//
//  RuleManager.swift
//  extension
//
//  Created by wesley on 2022/7/14.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SimpleLib
import SwiftyJSON

class RuleManager:NSObject{
        
        private var coreData:CDRuleVersion?
        public static var rInst = RuleManager()
        
        override init() {
                super.init()
        }
        
        func loadRulsByVersion() {
                
                var rVer = PersistenceController.shared.findOneEntity(AppConstants.DBNAME_RuleVer) as? CDRuleVersion
                if rVer == nil{
                        rVer = CDRuleVersion(context: PersistenceController.shared.container.viewContext)//PersistenceController.shared.NewItem() as? CDRuleVersion
                        rVer!.dnsVer = -1
                        rVer!.ipVer = -1
                        rVer!.mustVer = -1
                        rVer!.nodeVer = -1
                        rVer!.priceVer = -1
                        rVer!.dnsStr = loadTxtStr("rule")
                        rVer!.ipStr = loadTxtStr("bypass2")
                        rVer!.mustStr = loadTxtStr("must_hit")
                        rVer!.priceStr = ""
                        rVer!.nodeStr = ""
                        rVer!.macVer = -1
                        
                        PersistenceController.shared.saveContext()
                }
                
                self.coreData = rVer
                
                NodeItem.fullFillNodes(jsonStr: rVer?.nodeStr)
                PriceItem.pricePopulate(jsonStr:rVer?.priceStr)
                
                AppSetting.workQueue.async {
                        guard let verData = RuleVerInt() else{
                                NSLog("------>>>load rule version faile")
                                return
                        }
                        let version = String(cString: verData)
                        let jsonVer = JSON(parseJSON: version)
                        let dns_ver = jsonVer["dns"].int32 ?? -1
                        let ip_ver = jsonVer["by_pass"].int32 ?? -1
                        let mac_ver = jsonVer["macVer"].int32 ?? -1
                        let must_ver = jsonVer["must_hit"].int32 ?? -1
                        let node_ver = jsonVer["config"].int32 ?? -1
                        let price_ver = jsonVer["price"].int32 ?? -1
                        PriceItem.currency = jsonVer["dollar"].string ?? "cny"
                        
                        if mac_ver != rVer!.macVer{
                                rVer!.macVer = mac_ver
                        }
                        var needSave = false
                        if dns_ver > rVer!.dnsVer{
                                if let dnsStr = RuleDataLoad(){
                                        rVer?.dnsStr = String(cString: dnsStr)
                                        rVer?.dnsVer = dns_ver
                                        needSave = true
                                }else{
                                        NSLog("------>>> load dns rule failed:")
                                }
                        }
                        
                        if ip_ver > rVer!.ipVer{
                                if let ipStr = ByPassDataLoad() {
                                        rVer?.ipStr = String(cString: ipStr)
                                        rVer?.ipVer = ip_ver
                                        needSave = true
                                }else{
                                        NSLog("------>>> load ip rule failed:")
                                }
                        }
                        
                        if must_ver > rVer!.mustVer{
                                if let mustStr = MustHitData() {
                                        rVer?.mustStr = String(cString: mustStr)
                                        rVer?.mustVer = must_ver
                                        needSave = true
                                }else{
                                        NSLog("------>>> load must hit failed:")
                                }
                        }
                        
                        if node_ver > rVer!.nodeVer{
                                if let nodeStr = NodeConfigData() {
                                        rVer?.nodeVer = node_ver
                                        rVer?.nodeStr = String(cString: nodeStr)
                                        NodeItem.fullFillNodes(jsonStr: rVer?.nodeStr)
                                }else{
                                        NSLog("------>>> load node config failed:")
                                }
                        }
                        if price_ver > rVer!.priceVer{
                                if let priceStr = PriceConfigData() {
                                        rVer?.priceVer = price_ver
                                        rVer?.priceStr = String(cString: priceStr)
                                        PriceItem.pricePopulate(jsonStr:rVer?.priceStr)
                                }else{
                                        NSLog("------>>> load price config failed:")
                                }
                        }
                        
                        if needSave{
                                PersistenceController.shared.saveContext()
                                self.coreData = rVer
                                NSLog("------>>> rule version changed......")
                        }
                }
        }
        
        private func loadTxtStr(_ name:String)->String{
                guard let filepath = Bundle.main.path(forResource: name, ofType: "txt") else{
                        NSLog("------>>>failed to find \(name) text path")
                        return ""
                }
                guard let contents = try? String(contentsOfFile: filepath) else{
                        NSLog("------>>>failed to read  \(name) txt")
                        return ""
                }
                NSLog("------>>>rule contents:\(contents.count)")
                return contents
        }
        
        func domainStr()->String{
                return coreData?.dnsStr ?? ""
        }
        
        func innerIPStr()->String{
                return coreData?.ipStr ?? ""
        }
        
        func latstAPPVer()->Int32{
                return coreData?.macVer ?? -1
        }
}
