//
//  ASCLogger.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import os.log
import Pulse

var log = ASCLogger()

struct ASCLogger {
    private let osLog: OSLog
    private let s = DispatchSemaphore(value: 1)
    private let loggerInterceptor = ASCLoggerInterceptor()

    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        var displayName: String {
            switch self {
            case .debug:
                return "💬 DEBUG:"
            case .info:
                return "ℹ️ INFO:"
            case .warning:
                return "⚠️ WARNING:"
            case .error:
                return "⛔ ERROR:"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }

        var pulsaLoggerLevel: LoggerStore.Level {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .warning
            case .error: return .error
            }
        }

        static func < (lhs: ASCLogger.Level, rhs: ASCLogger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    typealias Hook = (String, Level) -> Void
    var hook: Hook?

    fileprivate init() {
        osLog = OSLog(subsystem: "\(Bundle.main.bundleIdentifier ?? "asc.onlyoffice.app")", category: "Documents")
        URLSessionProxyDelegate.ascEnableAutomaticRegistration()

        // Set delegate on Main actor since ASCLogIntercepter is @MainActor
        let interceptor = loggerInterceptor
        Task { @MainActor in
            ASCLogIntercepter.shared.delegate = interceptor
        }
    }

    private func log(_ level: Level, _ message: Any, _ arguments: [Any], function: String, line: UInt) {
        _ = s.wait(timeout: .now() + 0.033)
        defer { s.signal() }

        let extraMessage: String = arguments.map { String(describing: $0) }.joined(separator: " ")
        let log: String = {
            switch level {
            case .debug:
                return "\(level.displayName) \(message) \(extraMessage) (\(function):\(line))"
            default:
                return "\(level.displayName) \(message) \(extraMessage)"
            }
        }()

        hook?(log, level)

        #if !DEBUG
            os_log("%@", log: osLog, type: level.osLogType, log)
        #endif

        pulseLog(level, "\(message)", arguments, function: function, line: line)
    }

    private func getPrettyFunction(_ function: String, _ file: String) -> String {
        if let filename = file.split(separator: "/").last {
            return filename + ":" + function
        } else {
            return file + ":" + function
        }
    }

    func debug(_ log: Any, _ arguments: Any..., function: String = #function, file: String = #file, line: UInt = #line) {
        self.log(.debug, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func info(_ log: Any, _ arguments: Any..., function: String = #function, file: String = #file, line: UInt = #line) {
        self.log(.info, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func warning(_ log: Any, _ arguments: Any..., function: String = #function, file: String = #file, line: UInt = #line) {
        self.log(.warning, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func error(_ log: Any, _ arguments: Any..., function: String = #function, file: String = #file, line: UInt = #line) {
        self.log(.error, log, arguments, function: getPrettyFunction(function, file), line: line)
    }
}

class ASCLoggerInterceptor: ASCLogInterceptorDelegate {
    func log(message: String) {
        LoggerStore.shared.storeMessage(
            label: "Documents",
            level: .trace,
            message: "\(message)",
            metadata: nil
        )
    }
}

// MARK: - Pulse Logger extensions

extension ASCLogger {
    private func pulseLog(_ level: Level, _ message: Any, _ arguments: [Any], function: String, line: UInt) {
        LoggerStore.shared.storeMessage(
            label: "Documents",
            level: level.pulsaLoggerLevel,
            message: "\(message)",
            metadata: [
                "function": .string(function),
                "line": .string("\(line)"),
                "arguments": .string(arguments.map { String(describing: $0) }.joined(separator: " ")),
            ]
        )
    }
}

private let sharedNetworkLogger = NetworkLogger()

private extension URLSession {
    @objc class func asc_pulse_init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> URLSession {
        // TODO: Fix [#155](https://github.com/kean/Pulse/issues/155)
        guard !String(describing: delegate).contains("GTMSessionFetcher") else {
            return asc_pulse_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        }
        let delegate = URLSessionProxyDelegate(logger: sharedNetworkLogger, delegate: delegate)
        return asc_pulse_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
}

extension URLSessionProxyDelegate {
    static func ascEnableAutomaticRegistration() {
        if let lhs = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:delegate:delegateQueue:))),
           let rhs = class_getClassMethod(URLSession.self, #selector(URLSession.asc_pulse_init(configuration:delegate:delegateQueue:)))
        {
            method_exchangeImplementations(lhs, rhs)
        }
    }
}
