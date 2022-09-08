//
//  AccountManager.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/8.
//

import Cocoa

class AccountManager: NSWindowController {
        @IBOutlet var accountStrTF: NSTextField!
        @IBOutlet var qrCodeImgPathTF: NSSecureTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
        }
        
        @IBAction func ImportByStringData(_ sender: NSButton) {
                
                let accStr = accountStrTF.stringValue
                guard !accStr.isEmpty else{
                        return
                }
                
                let pwd = showPasswordDialog()
                guard !pwd.isEmpty else{
                        return
                }
                
                guard Wallet.ImportWallet(auth: pwd, josn: accStr) else{
                        dialogOK(question: "Error".localized, text: "Import Failed".localized)
                        return
                }
                
                
                dialogOK(question: "Success".localized, text: "")
                
                self.close()
        }
        
        @IBAction func QRScan(_ sender: NSButton) {
        }
}
