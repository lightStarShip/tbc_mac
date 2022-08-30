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
                return menu
        }
        
        @objc func about(sender: NSMenuItem) {
                NSApp.orderFrontStandardAboutPanel()
        }
        
        @objc func quit(sender: NSMenuItem) {
                NSApp.terminate(self)
        }
        
        
        @objc func setupNetwork(sender: NSMenuItem) {
                
                AppSetting.initSettting()
        }
}
