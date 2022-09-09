//
//  theBigDipperApp.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/16.
//

import SwiftUI


@main
struct theBigDipperApp: App {
        // swiftlint:disable:next weak_delegate
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        // This is our Scene. We are not using Settings
        var body: some Scene {
                Settings {
                        EmptyView()
                }
        }
}

class AppDelegate: NSObject, NSApplicationDelegate {
        static private(set) var instance: AppDelegate!
        
        private var statusItem: NSStatusItem!
        private var menu = MainMenu()
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                AppDelegate.instance = self
                
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                statusItem.button?.image = NSImage(named: NSImage.Name("logo"))
                statusItem.button?.imagePosition = .imageLeading
                statusItem.menu = menu.build()
                
                AppSetting.initSettting()
                if let subAddr = Wallet.WInst.SubAddress {
                        var pwd = AppSetting.readPassword(service: AppConstants.SERVICE_NME_FOR_OSS,
                                                          account: subAddr)
                        if pwd == nil{
                                pwd = showPasswordDialog()
                        }
                        
                        if !Wallet.WInst.OpenWallet(auth: pwd!){
                                dialogOK(question: "Error".localized, text: "open local account failed".localized)
                                return
                        }
                }
        }
}
