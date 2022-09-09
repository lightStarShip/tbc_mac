//
//  MainMenu.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/16.
//


import Cocoa
import SwiftUI

class MainMenu: NSObject {
        
        let menu = NSMenu()
        var nodeListNode = NSMenu()
        var accountWindow:AccountManager?
        
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
                
                
                // Adding a seperator
                menu.addItem(NSMenuItem.separator())
                
                let nodeItem = NSMenuItem(
                        title: "node List".localized,
                        action: nil,
                        keyEquivalent: ""
                )
                nodeItem.target = self
                menu.addItem(nodeItem)
                menu.setSubmenu(nodeListNode, for: nodeItem)
                
                let aboutMenuItem = NSMenuItem(
                        title: "About KyanBar",
                        action: #selector(about),
                        keyEquivalent: ""
                )
                aboutMenuItem.target = self
                menu.addItem(aboutMenuItem)
                
                menu.addItem(NSMenuItem.separator())
                
                
                let quitMenuItem = NSMenuItem(
                        title: "Quit KyanBar",
                        action: #selector(quit),
                        keyEquivalent: "q"
                )
                quitMenuItem.target = self
                
                menu.addItem(quitMenuItem)
                
                return menu
        }
        
        @objc func about(sender: NSMenuItem) {
                NSApp.orderFrontStandardAboutPanel()
        }
        
        @objc func choseFreeNodeItem(sender: NSMenuItem) {
                
        }
        
        @objc func choseVipNodeItem(sender: NSMenuItem) {
                
        }
        
        @objc func reloadNodeNenu(_ notification: Notification?) {
                nodeListNode.removeAllItems()
                
                print("------------->",AppSetting.coreData?.minerAddrInUsed)
                
                for (idx,node) in NodeItem.freeNodes.enumerated() {
                        let nodeItem = NSMenuItem(
                                title: node.location,
                                action: #selector(choseFreeNodeItem),
                                keyEquivalent: ""
                        )
                        nodeItem.tag =  idx
                        nodeItem.target = self
                        nodeListNode.addItem(nodeItem)
                }
                
                menu.addItem(NSMenuItem.separator())
                
                for (idx, node) in NodeItem.vipNodes.enumerated() {
                        let nodeItem = NSMenuItem(
                                title: node.location,
                                action: #selector(choseVipNodeItem),
                                keyEquivalent: ""
                        )
                        nodeItem.tag =  idx
                        nodeItem.target = self
                        nodeListNode.addItem(nodeItem)
                }
        }
        
        private func showAccountImport(){
                if(accountWindow == nil) {
                        accountWindow = AccountManager(windowNibName: "AccountManager")
                        accountWindow!.showWindow(nil)
                }
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                accountWindow!.window?.orderFrontRegardless()
                accountWindow?.resetContent()
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
