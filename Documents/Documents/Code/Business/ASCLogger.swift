//
//  ASCLogger.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Foundation
import os.log

var log = {
    return ASCLogger()
}()


struct ASCLogger {
    private let osLog: OSLog
    private let s = DispatchSemaphore(value: 1)

    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        var displayName: String {
            switch self {
            case .debug:
                return "🟣 DEBUG:"
            case .info:
                return "🔵 INFO:"
            case .warning:
                return "🟡 WARNING:"
            case .error:
                return "🔴 ERROR:"
            }
        }
        @available(iOS 10.0, *)
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }

        static func < (lhs: ASCLogger.Level, rhs: ASCLogger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    typealias Hook = ((String, Level) -> Void)
    var hook: Hook?

    fileprivate init() {
        osLog = OSLog(subsystem: "\(Bundle.main.bundleIdentifier ?? "asc.onlyoffice.app")", category: "Documents")
    }

    private func log(_ level: Level, _ message: Any, _ arguments: [Any], function: String, line: UInt) {
        _ = s.wait(timeout: .now() + 0.033)
        defer { s.signal() }

        let extraMessage: String = arguments.map({ String(describing: $0) }).joined(separator: " ")
        let log: String = {
            switch level {
            case .debug:
                return "\(level.displayName) \(message) \(extraMessage) (\(function):\(line))"
            default:
                return "\(level.displayName) \(message) \(extraMessage)"
            }
        }()

        hook?(log, level)

        os_log("%@", log: osLog, type: level.osLogType, log)
    }

    private func getPrettyFunction(_ function: String, _ file: String) -> String {
        if let filename = file.split(separator: "/").last {
            return filename + ":" + function
        } else {
            return file + ":" + function
        }
    }

    func debug(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.debug, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func info(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.info, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func warning(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.warning, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func error(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.error, log, arguments, function: getPrettyFunction(function, file), line: line)
    }
}
