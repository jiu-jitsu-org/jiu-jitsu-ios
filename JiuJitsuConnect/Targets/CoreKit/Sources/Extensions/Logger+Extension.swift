//
//  Logger+Extension.swift
//  CoreKit
//
//  Created by suni on 9/29/25.
//

import Foundation
import OSLog

public extension Logger {
    /// 앱의 고유한 Subsystem Identifier
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// DEBUG
    static let debug = Logger(subsystem: subsystem, category: "Debug")
    
    /// 네트워크 통신 관련 로그
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    /// 데이터베이스 및 저장소 관련 로그
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    
    /// UI 및 View 라이프사이클 관련 로그
    static let view = Logger(subsystem: subsystem, category: "View")
}
