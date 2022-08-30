//
//  AppErr.swift
//  theBigDipper
//
//  Created by wesley on 2022/8/30.
//

import Foundation
public enum AppErr: Error,LocalizedError {
        case system(String)
        
        public var errorDescription: String? {
                
                switch self {
                case .system(let err): return "\(err)"
                }
        }
}
