//
//  ImportAccount.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/6.
//

import SwiftUI
import SimpleLib

struct NodeActionView: View {
        var body: some View {
                HStack{
                        Button("Ping Test") {
                                let dispatchGrp = DispatchGroup()
                                for node in NodeItem.vipNodes{
                                        dispatchGrp.enter()
                                        AppSetting.workQueue.async(group:dispatchGrp) {
                                                defer{ dispatchGrp.leave()}
                                                node.pings = LibGetPingVal(node.wallet.toGoString(), node.ipStr.toGoString())
                                        }
                                }
                                for node in NodeItem.freeNodes {
                                        dispatchGrp.enter()
                                        AppSetting.workQueue.async(group:dispatchGrp) {
                                                defer{ dispatchGrp.leave()}
                                                node.pings = LibGetPingVal(node.wallet.toGoString(), node.ipStr.toGoString())
                                        }
                                }
                                
                                dispatchGrp.notify(queue: DispatchQueue.main){
                                        PostNoti(AppConstants.NOTI_NODE_LIST_UPDATE)
                                }
                        }
                        
                        Button("Reload Nodes") {
                                RuleManager.rInst.loadRulsByVersion()
                        }
                }
        }
}

struct NodeActionView_Previews: PreviewProvider {
        static var previews: some View {
                NodeActionView()
        }
}
