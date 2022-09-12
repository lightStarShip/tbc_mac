//
//  AppErr.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/30.
//

import Foundation
public enum AppErr: Error,LocalizedError {
        case system(String)
        case lib(String)
        case conf(String)
        case stripe(String)
        case wallet(String)
        case proxySet(String)
        
        public var errorDescription: String? {
                
                switch self {
                case .system(let err): return "\(err)"
                case .lib(let err): return "\(err)"
                case .conf(let err): return "\(err)"
                case .stripe(let err): return "\(err)"
                case .wallet(let err): return "\(err)"
                case .proxySet(let err): return "\(err)"
                }
        }
}
