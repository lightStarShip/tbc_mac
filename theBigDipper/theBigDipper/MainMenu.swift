//
//  MainMenu.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/16.
//


import Cocoa
import SwiftUI
import SimpleLib

class MainMenu: NSObject {
        
        let menu = NSMenu()
        var nodeListMenu = NSMenu()
        var accountImport:AccountManager?
        var helpWindow:HelpToRecharge?
        var accInfo:AccountBalance?
        
        private var popover:NSPopover?
        
        func build() ->NSMenu{
                
                NotificationCenter.default.addObserver(self, selector: #selector(reloadNodeNenu(_:)),
                                                       name: AppConstants.NOTI_NODE_LIST_UPDATE, object: nil)
                menu.addItem(NSMenuItem.separator())
                
                // Adding a seperator
                let setupNetworkItem = NSMenuItem(
                        title: "Turn On".localized,
                        action: #selector(setupNetwork),
                        keyEquivalent: ""
                )
                
                setupNetworkItem.target = self
                menu.addItem(setupNetworkItem)
                
                
                menu.addItem(NSMenuItem.separator())
                
                let nodeItem = NSMenuItem(
                        title: "node List".localized,
                        action: nil,
                        keyEquivalent: ""
                )
                nodeItem.target = self
                menu.addItem(nodeItem)
                
                menu.setSubmenu(nodeListMenu, for: nodeItem)
                
                
                let accInfo = NSMenuItem(
                        title: "Account".localized,
                        action: #selector(showAccountInfo),
                        keyEquivalent: ""
                )
                accInfo.target = self
                menu.addItem(accInfo)
                
                
                let copyProxy = NSMenuItem(
                        title: "Copy Command Line".localized,
                        action: #selector(copyCmdLine),
                        keyEquivalent: ""
                )
                copyProxy.target = self
                menu.addItem(copyProxy)
                
                let helpWebMenuItem = NSMenuItem(
                        title: "Find Help".localized,
                        action: #selector(findHelp),
                        keyEquivalent: ""
                )
                helpWebMenuItem.target = self
                menu.addItem(helpWebMenuItem)
                
                let aboutMenuItem = NSMenuItem(
                        title: "About TheBigDipper".localized,
                        action: #selector(about),
                        keyEquivalent: ""
                )
                aboutMenuItem.target = self
                menu.addItem(aboutMenuItem)
                
                menu.addItem(NSMenuItem.separator())
                
                let quitMenuItem = NSMenuItem(
                        title: "Quit".localized,
                        action: #selector(quit),
                        keyEquivalent: "q"
                )
                quitMenuItem.target = self
                
                menu.addItem(quitMenuItem)
                
                return menu
        }
        
        @objc func findHelp(sender: NSMenuItem) {
                let url = URL(string: AppConstants.WebSite)!
                NSWorkspace.shared.open(url)
        }
        
        @objc func copyCmdLine(sender: NSMenuItem) {
                let pasteBoard = NSPasteboard.general
                pasteBoard.clearContents()
                pasteBoard.setString(AppConstants.CmdLineProxy, forType: .string)
        }
        
        @objc func about(sender: NSMenuItem) {
                NSApp.orderFrontStandardAboutPanel()
        }
        
        @objc func choseFreeNodeItem(sender: NSMenuItem) {
                let node = NodeItem.freeNodes[sender.tag]
                setnodeInfo(node:node, sender: sender)
        }
        
        @objc func choseVipNodeItem(sender: NSMenuItem) {
                let node = NodeItem.vipNodes[sender.tag]
                setnodeInfo(node:node, sender: sender)
        }
        
        private func setnodeInfo(node:NodeItem, sender: NSMenuItem){
                if node.wallet == AppSetting.coreData?.minerAddrInUsed{
                        return
                }
                
                for item in nodeListMenu.items {
                        item.state = .off
                }
                sender.state = .on
                AppSetting.coreData?.minerAddrInUsed = node.wallet
                sender.parent?.title = node.location
                if let err = NodeItem.changeNode(node:node){
                        dialogOK(question: "Error".localized, text: err.localizedDescription)
                }
        }
        
        @objc func showHelpToRecharge(sender: NSMenuItem) {
                if(helpWindow == nil) {
                        helpWindow = HelpToRecharge(windowNibName: "HelpToRecharge")
                        helpWindow!.showWindow(nil)
                }
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                helpWindow!.window?.orderFrontRegardless()
        }
        
        
        
        @objc func showAccountInfo(sender: NSMenuItem) {
                if(accInfo == nil) {
                        accInfo = AccountBalance(windowNibName: "AccountBalance")
                        accInfo!.showWindow(nil)
                }
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                accInfo!.window?.orderFrontRegardless()
                accInfo?.setAccInfo()
        }
        
        @objc func testAllNode(sender: NSMenuItem) {
                
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
                        self.reloadNodeNenu(nil)
                }
        }
        
        @objc func reloadNodeNenu(_ notification: Notification?) {
                nodeListMenu.removeAllItems()
                
                let curAddr = AppSetting.coreData?.minerAddrInUsed
                let testButton = NSMenuItem(
                        title: "Ping Test".localized,
                        action: #selector(testAllNode),
                        keyEquivalent: ""
                )
                
                testButton.target = self
                nodeListMenu.addItem(testButton)
                
                nodeListMenu.addItem(NSMenuItem.separator())
                let freeTips = NSMenuItem(
                        title: "Free Nodes".localized,
                        action: nil,
                        keyEquivalent: ""
                )
                nodeListMenu.addItem(freeTips)
                nodeListMenu.addItem(NSMenuItem.separator())
                
                for (idx,node) in NodeItem.freeNodes.enumerated() {
                        let nodeItem = NSMenuItem(
                                title: node.menuTitle(),
                                action: #selector(choseFreeNodeItem),
                                keyEquivalent: ""
                        )
                        nodeItem.tag =  idx
                        nodeItem.target = self
                        if curAddr == node.wallet{
                                nodeItem.state = .on
                        }
                        nodeListMenu.addItem(nodeItem)
                }
                
                
                nodeListMenu.addItem(NSMenuItem.separator())
                if !Stripe.SInst.IsVipUser(){
                        nodeListMenu.addItem(NSMenuItem.separator())
                        let VipTips = NSMenuItem(
                                title: "VIP Recharge".localized,
                                action: #selector(showHelpToRecharge),
                                keyEquivalent: ""
                        )
                        VipTips.target = self
                        nodeListMenu.addItem(VipTips)
                        return
                }
                
                let VipTips = NSMenuItem(
                        title: "Vip Nodes".localized,
                        action: nil,
                        keyEquivalent: ""
                )
                nodeListMenu.addItem(VipTips)
                nodeListMenu.addItem(NSMenuItem.separator())
                
                for (idx, node) in NodeItem.vipNodes.enumerated() {
                        let nodeItem = NSMenuItem(
                                title: node.menuTitle(),
                                action: #selector(choseVipNodeItem),
                                keyEquivalent: ""
                        )
                        nodeItem.tag =  idx
                        nodeItem.target = self
                        if curAddr == node.wallet{
                                nodeItem.state = .on
                        }
                        nodeListMenu.addItem(nodeItem)
                }
        }
        
        private func showAccountImport(){
                if(accountImport == nil) {
                        accountImport = AccountManager(windowNibName: "AccountManager")
                        accountImport!.showWindow(nil)
                }
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                accountImport!.window?.orderFrontRegardless()
                accountImport?.resetContent()
        }
        
        @objc func quit(sender: NSMenuItem) {
                _ = AppSetting.setupProxy(on: false)
                NSApp.terminate(self)
        }
        
        
        @objc func setupNetwork(sender: NSMenuItem) {
                
                if Wallet.WInst.SubAddress == nil{
                        showAccountImport()
                        return
                }
                
                if AppSetting.proxyIsOn(){
                        if let err = AppSetting.setupProxy(on: false){
                                dialogOK(question: "Error".localized, text: "setup proxy failed".localized)
                                print("------>>> setupProxy:\(err.localizedDescription)")
                                return
                        }
                        sender.title = "Turn On".localized
                        return
                }
                
                if let err = AppSetting.setupProxy(on: true){
                        dialogOK(question: "Error".localized, text: "setup proxy failed".localized)
                        print("------>>> setupProxy:\(err.localizedDescription)")
                        return
                }
                sender.title = "Turn Off".localized
        }
}
