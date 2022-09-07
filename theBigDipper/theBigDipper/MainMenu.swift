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
        var settingsWindow:NSWindowController?
        
        private var popover:NSPopover?
        
        func build() ->NSMenu{
                menu.addItem(NSMenuItem.separator())
                
                
                // Adding a seperator
                let setupNetworkItem = NSMenuItem(
                        title: "Turn On",
                        action: #selector(setupNetwork),
                        keyEquivalent: ""
                )
                setupNetworkItem.target = self
                menu.addItem(setupNetworkItem)
                
                // Adding a seperator
                let aboutMenuItem = NSMenuItem(
                        title: "About KyanBar",
                        action: #selector(about),
                        keyEquivalent: ""
                )
                aboutMenuItem.target = self
                menu.addItem(aboutMenuItem)
                
                // Adding a seperator
                menu.addItem(NSMenuItem.separator())
                
                
                // Adding a quit menu item
                let quitMenuItem = NSMenuItem(
                        title: "Quit KyanBar",
                        action: #selector(quit),
                        keyEquivalent: "q"
                )
                quitMenuItem.target = self
                
                menu.addItem(quitMenuItem)

                let showPop = NSMenuItem(
                        title: "Pop On",
                        action: #selector(togglePopover),
                        keyEquivalent: ""
                )
                showPop.target = self
                menu.addItem(showPop)
                
                return menu
        }
        
        @objc func about(sender: NSMenuItem) {
                NSApp.orderFrontStandardAboutPanel()
        }
        
        @objc func togglePopover(sender: NSMenuItem) {
                if(settingsWindow == nil) {
                        let detailView = ImportAccountView();
                       settingsWindow = AccountWindow(rootView: detailView)
                       settingsWindow!.window?.title = "Cloud Brains - Settings";
                       settingsWindow!.showWindow(nil)
                   }
                   NSApp.setActivationPolicy(.prohibited)
                   NSApp.activate(ignoringOtherApps: true)
                   settingsWindow!.window?.orderFrontRegardless()
        }
        
        @objc func quit(sender: NSMenuItem) {
                NSApp.terminate(self)
        }
        
        
        @objc func setupNetwork(sender: NSMenuItem) {
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
