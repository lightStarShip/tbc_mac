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
        private var popover:NSPopover!
        @State public var showingPopover = false
        private var menu:MainMenu!
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                AppDelegate.instance = self
                
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                statusItem.button?.image = NSImage(named: NSImage.Name("logo"))
                statusItem.button?.imagePosition = .imageLeading
                menu = MainMenu()
                statusItem.menu = menu.build()
                
                let showPop = NSMenuItem(
                        title: "Pop On",
                        action: #selector(togglePopover),
                        keyEquivalent: ""
                )
                statusItem.menu!.addItem(showPop)
                
                AppSetting.initSettting()
                
                self.popover = NSPopover()
                self.popover.contentSize = NSSize(width: 600, height: 600)
                self.popover.behavior = .transient
                self.popover.contentViewController = NSHostingController(rootView: ImportAccountView())
        }
        
        @objc func togglePopover() {
                if let button = statusItem.button {
                        if popover.isShown {
                                self.popover.performClose(nil)
                        } else {
                                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                        }
                }
        }
}
