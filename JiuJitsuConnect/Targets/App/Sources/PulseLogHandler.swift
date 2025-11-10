//
//  PulseLogHandler.swift
//  App
//
//  Created by suni on 11/10/25.
//

import Foundation
import Pulse
import CoreKit

struct PulseLogHandler: LogHandler {
    func log(level: LogLevel, label: String, message: String, file: String, function: String, line: UInt) {
        LoggerStore.shared.storeMessage(
            label: label,
            level: level.toPulseLevel(), // LogLevel -> Pulse.Level 변환
            message: message,
            file: file, function: function, line: line
        )
    }
}

private extension LogLevel {
    func toPulseLevel() -> LoggerStore.Level {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
}
