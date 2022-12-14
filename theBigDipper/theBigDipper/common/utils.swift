//
//  utils.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation
import Cocoa
import SimpleLib
import SystemConfiguration

extension String {
        var localized: String {
                return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
        func format(parameters: CVarArg...) -> String {
                return String(format: self, arguments: parameters)
        }
        
        func toGoString() ->GoString {
                let cs = (self as NSString).utf8String
                let buffer = UnsafePointer<Int8>(cs!)
                return GoString(p:buffer, n:strlen(buffer))
        }
        
        func toCString()->UnsafeMutablePointer<CChar>{
                return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
        }
}

func VersionToInt(ver:String)->Int32{
        let result = ver.split(separator: ".")
        if result.count != 3{
                return -1
        }
        return (result[0] as NSString).intValue * 10000 + (result[1] as NSString).intValue * 100 + (result[2] as NSString).intValue
}

func dialogOK(question: String, text: String) -> Void {DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = question.localized
        alert.informativeText = text.localized
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK".localized)
        alert.runModal()
}
}

func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question.localized
        alert.informativeText = text.localized
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK".localized)
        alert.addButton(withTitle: "Cancel".localized)
        return alert.runModal() == .alertFirstButtonReturn
}


public func PostNoti(_ namedNoti:Notification.Name, data:String? = nil){
        NotificationCenter.default.post(name: namedNoti, object: nil, userInfo: ["data":data ?? ""])
}


func showPasswordDialog() -> String {
        let alert = NSAlert()
        alert.messageText = "Account Password".localized
        alert.informativeText = "Please input the password of this account".localized
        alert.alertStyle = .informational
        let input = NSSecureTextField.init(frame: NSRect.init(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        alert.addButton(withTitle: "OK".localized)
        alert.addButton(withTitle: "Cancel".localized)
        let butSel = alert.runModal()
        if butSel == .alertFirstButtonReturn{
                return input.stringValue
        }
        return ""
}

extension NSTextView {
        override open func performKeyEquivalent(with event: NSEvent) -> Bool {
                let commandKey = NSEvent.ModifierFlags.command.rawValue
                let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
                if event.type == NSEvent.EventType.keyDown {
                        if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                                switch event.charactersIgnoringModifiers! {
                                case "x":
                                        if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                                case "c":
                                        if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                                case "v":
                                        if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                                case "z":
                                        if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                                case "a":
                                        if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                                default:
                                        break
                                }
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                                if event.charactersIgnoringModifiers == "Z" {
                                        if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                                }
                        }
                }
                return super.performKeyEquivalent(with: event)
        }
}


func OpenImgFilePath()->URL? {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose an image | Our Code World";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = false;
        dialog.allowedFileTypes        = ["png", "jpg", "jpeg", "gif"];
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
                return dialog.url
        }
        
        return nil
        
}


func generateQRCode(from message: String) -> NSImage? {
        
        guard let data = message.data(using: .utf8) else{
                return nil
        }
        
        guard let qr = CIFilter(name: "CIQRCodeGenerator",
                                parameters: ["inputMessage":
                                                data, "inputCorrectionLevel":"M"]) else{
                return nil
        }
        
        guard let qrImage = qr.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5)) else{
                return nil
        }
        let context = CIContext()
        let cgImage = context.createCGImage(qrImage, from: qrImage.extent)
        let uiImage = NSImage(cgImage: cgImage!, size: qrImage.extent.size)
        return uiImage
}
