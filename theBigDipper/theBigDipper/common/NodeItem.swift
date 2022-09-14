//
//  NodeItem.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/9.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import SwiftyJSON
import SimpleLib

class NodeItem : NSObject {
        public static var vipNodes:[NodeItem] = []
        public static var freeNodes:[NodeItem] = []
        var isFree = false
        var ipStr = ""
        var location = ""
        var icon = ""
        var wallet = ""
        var pings:Float = -1.0
        
        init(json:JSON){
                super.init()
                self.location = json["location"].string ?? "Free"
                self.icon = json["icon"].string ?? "Free"
                self.ipStr = json["ip"].string ?? "-1"
                self.wallet = json["address"].string ?? "<>"
                self.pings = -1.0
                self.isFree = json["free"].bool ?? false
        }
        
        public static func fullFillNodes(jsonStr:String?, needNoti:Bool?=false){
                guard let str = jsonStr, !str.isEmpty else{
                        return
                }
                vipNodes.removeAll()
                freeNodes.removeAll()
                let nodeArr = JSON(parseJSON: str)
                for (_, subJson):(String, JSON) in nodeArr {
                        let item = NodeItem(json:subJson)
                        if item.isFree{
                                freeNodes.append(item)
                        }else{
                                vipNodes.append(item)
                        }
                }
                if needNoti == true{
                        PostNoti(AppConstants.NOTI_NODE_LIST_UPDATE)
                }
        }
        
        public static func GetNode(addr:String?) -> NodeItem?{
                var randomFreeNOde:NodeItem? = nil
                let isVip = Stripe.SInst.IsVipUser()
                
                for free_node in freeNodes{
                        if addr == free_node.wallet{
                                return free_node
                        }
                        if randomFreeNOde == nil{
                                randomFreeNOde = free_node
                        }
                }
                
                if !isVip || addr == nil{
                        return randomFreeNOde
                }
                
                for vipNode in vipNodes {
                        if addr == vipNode.wallet{
                                return vipNode
                        }
                }
                return randomFreeNOde
        }
        
        public static func parseNodePort(nodeAddr:String)->(Int32) {
                return MinerPort(nodeAddr.toGoString())
        }
        
        public static func changeNode(node:NodeItem)->Error?{
                guard let err = ChangeNode(node.ipStr.toGoString(), node.wallet.toGoString()) else{
                        return nil
                }
                
                return AppErr.lib("change node err:\(String(cString: err))")
        }
        
        public func menuTitle()->String{
                return String(format: "%@        %0.2f ms",self.location, self.pings)
        }
}
