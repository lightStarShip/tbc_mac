//
//  PriceItem.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/7.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import SwiftyJSON

class PriceItem:NSObject{
        
        public static var items:[PriceItem] = [ ]
        public static var  currency:String = "cny"
        
        static let sign_currency:[String:String] = [
                "usd":"$",
                "cny":"￥",
                "hkd":"HK$",
                "eur":"€",
        ]
        
        var price:Double = 0.0
        var days:Int = 0
        var title:String = ""
        var id:String = ""
        var avPrice:String = ""
    
        init(price:Double, title:String, avPrice:String, id:String?=nil){
                super.init()
                self.price = price
                self.title = title
                self.avPrice = avPrice
                self.id = id ?? ""
        }
        
        init(json:JSON){
                super.init()
                self.id = json["id"].string ?? "-"
                self.title = json["tittle"].string ?? "Free"
                self.price = json["sum"].double ?? -1.0
                self.days = json["days"].int ?? -1
                let av_price = json["price"].double ?? -1.0
                self.avPrice = "\(av_price)/"+"M".localized
        }
        
        public static func pricePopulate(jsonStr:String?,needNoti:Bool=false){
                guard let str = jsonStr else{
                        return
                }
                items.removeAll()
                let nodeArr = JSON(parseJSON: str)
                for (_, subJson):(String, JSON) in nodeArr {
                        let item = PriceItem(json:subJson)
                        items.append(item)
                }
                if needNoti{
                        PostNoti(AppConstants.NOTI_PRICE_LIST_UPDATE)
                }
        }
}
