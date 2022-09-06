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
