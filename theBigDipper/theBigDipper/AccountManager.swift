//
//  AccountManager.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/8.
//

import Cocoa

class AccountManager: NSWindowController {
        @IBOutlet var accountStrTF: NSTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
                
                // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        }
        
        @IBAction func ImportByStringData(_ sender: NSButton) {
                let pwd = showPasswordDialog()
                print("------>>>\(pwd)")
        }
        
}
