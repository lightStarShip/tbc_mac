//
//  MenualRule.swift
//  theBigDipper
//
//  Created by wesley on 2022/10/19.
//

import Cocoa

class MenualRule: NSWindowController {
        
        @IBOutlet var domainSufix: NSTextField!
        @IBOutlet var tableView: NSTableView!
        override func windowDidLoad() {
                super.windowDidLoad()
        }
        
        @IBAction func addAction(_ sender: NSButton) {
                let domain = domainSufix.stringValue
                guard !domain.isEmpty else{
                        return
                }
        }
        
        func reset(){
                domainSufix?.stringValue = ""
        }
}
