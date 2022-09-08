//
//  AccountManager.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/8.
//

import Cocoa

class AccountManager: NSWindowController {
        @IBOutlet var accountStrTF: NSTextField!
        @IBOutlet var qrCodeImagePathLabel: NSTextField!
        
        
        override func windowDidLoad() {
                super.windowDidLoad()
        }
        
        func resetContent(){
                accountStrTF.stringValue = ""
                qrCodeImagePathLabel.stringValue = ""
        }
        
        @IBAction func ImportByStringData(_ sender: NSButton) {
                
                var accStr = accountStrTF.stringValue
                let imagePath = qrCodeImagePathLabel.stringValue
                
                guard !accStr.isEmpty || !imagePath.isEmpty else{
                        return
                }
                
                if accStr.isEmpty{
                        guard let str = Wallet.ParseAccountQRInmage(path: imagePath) else{
                                dialogOK(question: "Error".localized, text: "Parse QR Code Failed".localized)
                                return
                        }
                        accStr = str
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
                guard let url = OpenImgFilePath() else{
                        return
                }
                
                qrCodeImagePathLabel.stringValue = url.path
                accountStrTF.stringValue = ""
        }
}
