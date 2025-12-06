//
//  Log.swift
//  CoreKit
//
//  Created by suni on 11/10/25.
//

import Foundation
import OSLog

/// 프로젝트 전체에서 사용할 중앙 집중식 로거입니다.
/// 사용법: Log.trace("메시지", category: .network, level: .info)
public enum Log {
    
    /// 로그 카테고리를 정의합니다. 이모지와 라벨을 커스텀할 수 있습니다.
    public enum Category {
        case debug
        case network
        case storage
        case view
        case system
        case custom(label: String, emoji: String)
        
        /// Pulse에 표시될 라벨 문자열입니다.
        var name: String {
            switch self {
            case .debug: return "Debug"
            case .network: return "Network"
            case .storage: return "Storage"
            case .view: return "View"
            case .system: return "System"
            case .custom(let label, _): return label
            }
        }
        
        /// Xcode 콘솔에 표시될 이모지입니다.
        var emoji: String {
            switch self {
            case .debug: return "🛠️"
            case .network: return "🚀"
            case .storage: return "📦"
            case .view: return "🖼️"
            case .system: return "⚙️"
            case .custom(_, let emoji): return emoji
            }
        }
        
        /// OSLog에 사용할 Logger 인스턴스입니다.
        fileprivate var osLogger: Logger {
            switch self {
            case .debug: return ._debug
            case .network: return ._network
            case .storage: return ._storage
            case .view: return ._view
            case .system: return ._system
            case .custom(let label, _):
                // 커스텀 카테고리를 위한 Logger 동적 생성
                return Logger(subsystem: Bundle.main.bundleIdentifier!, category: label)
            }
        }
    }
    
    public static var handler: LogHandler?

    public static func trace(
        _ message: String,
        category: Category = .debug,
        level: OSLogType = .default,
        file: String = #file, function: String = #function, line: UInt = #line
    ) {
        // 1. Xcode 콘솔에는 기존처럼 로그를 남깁니다.
        category.osLogger.log(level: level, "\(category.emoji) \(message)")
        
        #if DEBUG
        // 2. 외부에서 주입된 핸들러를 통해 로그를 전달합니다.
        handler?.log(
            level: level.toLogLevel(),
            label: category.name,
            message: message,
            file: file, function: function, line: line
        )
        #endif
    }
}

// MARK: - OSLogType to Pulse.Level Conversion
private extension OSLogType {
    func toLogLevel() -> LogLevel {
        switch self {
        case .debug: return .debug
        case .info, .default: return .info
        case .error: return .error
        case .fault: return .critical
        default: return .info
        }
    }
}

// MARK: - Private Logger Instances
// 기존 Logger 정의는 private으로 변경하여 직접적인 접근을 막고 Log.trace를 통하도록 유도합니다.
private extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let _debug = Logger(subsystem: subsystem, category: "Debug")
    static let _network = Logger(subsystem: subsystem, category: "Network")
    static let _storage = Logger(subsystem: subsystem, category: "Storage")
    static let _view = Logger(subsystem: subsystem, category: "View")
    static let _system = Logger(subsystem: subsystem, category: "System")
}

public enum LogLevel {
    case debug, info, error, critical
}

public protocol LogHandler {
    func log(level: LogLevel, label: String, message: String, file: String, function: String, line: UInt)
}
