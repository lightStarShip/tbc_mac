//
//  AccountBalance.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/13.
//

import Cocoa

class AccountBalance: NSWindowController {
        
        @IBOutlet var blockchainWallet: NSTextField!
        @IBOutlet var balance: NSTextField!
        @IBOutlet var accID: NSTextField!
        @IBOutlet var accountQR: NSImageView!
        
        override func windowDidLoad() {
                super.windowDidLoad()
        }
        
        @IBAction func copyAccID(_ sender: NSButton) {
        }
        
        func setAccInfo(){
                
                guard let wAddr = Stripe.SInst.walletAddr else{
                        return
                }
                
                blockchainWallet.stringValue = wAddr
                if let cusID = Stripe.SInst.customerID{
                        accID.stringValue =  cusID
                        accountQR.image = generateQRCode(from: cusID)
                }
                
                balance.stringValue = String(format: "%.2f", Stripe.SInst.getBalanceInDays())
        }
}
