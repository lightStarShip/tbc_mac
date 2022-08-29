//
//  utils.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/29.
//

import Foundation
import SimpleLib

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
//        
//        func md5() -> String {
//                let str = self.cString(using: String.Encoding.utf8)
//                let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
//                let digestLen = Int(CC_MD5_DIGEST_LENGTH)
//                let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
//                CC_MD5(str!, strLen, result)
//                let hash = NSMutableString()
//                for i in 0 ..< digestLen {
//                        hash.appendFormat("%02x", result[i])
//                }
//                free(result)
//                return String(format: hash as String)
//        }
}
