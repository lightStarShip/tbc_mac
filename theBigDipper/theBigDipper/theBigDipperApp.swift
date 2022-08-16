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

// Our AppDelegae will handle our menu
class AppDelegate: NSObject, NSApplicationDelegate {
  static private(set) var instance: AppDelegate!

  // The NSStatusBar manages a collection of status items displayed within a system-wide menu bar.
  lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  
  // Create an instance of our custom main menu we are building
  let menu = MainMenu()

 
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    AppDelegate.instance = self


    // Here we are using a custom icon found in Assets.xcassets
    statusBarItem.button?.image = NSImage(named: NSImage.Name("logo"))
    statusBarItem.button?.imagePosition = .imageLeading
    // Assign our custom menu to the status bar
          statusBarItem.menu = menu.build()
  }
}
