//
//  ASCLogIntercepter.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCLogInterceptorDelegate: AnyObject {
    func log(message: String)
}

// MARK: - LogWriterActor

/// Actor responsible for thread-safe file writing operations
actor LogWriterActor {
    private var logURL: URL?
    private var fileHandle: FileHandle?
    private var pendingWrites: [String] = []
    private var isWriting = false
    private let maxBufferSize = 100 // Maximum number of pending writes

    /// Initialize the log writer with a file URL
    func initialize(logURL: URL) async throws {
        self.logURL = logURL

        // Create initial log header
        let header = """
        Start logger
        DeviceID: \(await UIDevice.current.identifierForVendor?.uuidString ?? "none")

        """

        try header.write(to: logURL, atomically: true, encoding: .utf8)
    }

    /// Write a log message asynchronously
    func writeLog(_ message: String) async {
        pendingWrites.append(message)

        // Prevent buffer overflow
        if pendingWrites.count > maxBufferSize {
            pendingWrites.removeFirst(pendingWrites.count - maxBufferSize)
        }

        // Process writes if not already writing
        if !isWriting {
            await processWrites()
        }
    }

    /// Process all pending writes
    private func processWrites() async {
        guard !pendingWrites.isEmpty, let logURL = logURL else { return }

        isWriting = true
        defer { isWriting = false }

        let writesToProcess = pendingWrites
        pendingWrites.removeAll()

        do {
            // Batch write all pending messages
            let combinedMessage = writesToProcess.joined(separator: "\n") + "\n"
            try await writeToFile(combinedMessage, url: logURL)
        } catch {
            // On error, put messages back to retry later
            pendingWrites.insert(contentsOf: writesToProcess, at: 0)
        }
    }

    /// Write data to file with proper error handling
    private func writeToFile(_ content: String, url: URL) async throws {
        guard let data = content.data(using: .utf8) else { return }

        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: url, options: .atomic)
        }
    }

    /// Flush all pending writes
    func flush() async {
        if !pendingWrites.isEmpty {
            await processWrites()
        }
    }

    /// Cleanup resources
    func cleanup() async {
        await flush()
        fileHandle?.closeFile()
        fileHandle = nil
        pendingWrites.removeAll()
    }
}

// MARK: - ASCLogIntercepter

@MainActor
class ASCLogIntercepter {
    static let shared = ASCLogIntercepter()

    // MARK: - Properties

    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private let logWriter = LogWriterActor()

    weak var delegate: ASCLogInterceptorDelegate?
    lazy var logUrl: URL? = {
        if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let documentsDirectory = URL(fileURLWithPath: path)
            return documentsDirectory.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app")-output.log")
        }
        return nil
    }()

    // MARK: - Lifecycle Methods

    func start() {
        Task {
            if let logUrl = logUrl {
                do {
                    try await logWriter.initialize(logURL: logUrl)
                } catch {
                    print("Failed to initialize log writer: \(error)")
                }
            }

            await MainActor.run {
                self.openConsolePipe()
            }
        }
    }

    private func openConsolePipe() {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)

        // open a new Pipe to consume the messages on STDOUT and STDERR
        inputPipe = Pipe()

        // open another Pipe to output messages back to STDOUT
        outputPipe = Pipe()

        guard let inputPipe = inputPipe, let outputPipe = outputPipe else {
            return
        }

        let pipeReadHandle = inputPipe.fileHandleForReading

        /// from documentation
        /// dup2() makes newfd (new file descriptor) be the copy of oldfd
        /// (old file descriptor), closing newfd first if necessary.

        /// here we are copying the STDOUT file descriptor into our output
        /// pipe's file descriptor this is so we can write the strings back
        /// to STDOUT, so it can show up on the xcode console
        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)

        /// In this case, the newFileDescriptor is the pipe's file descriptor
        /// and the old file descriptor is STDOUT_FILENO and STDERR_FILENO

        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // listen in to the readHandle notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePipeNotification),
            name: FileHandle.readCompletionNotification,
            object: pipeReadHandle
        )

        // state that you want to be notified of any data coming across the pipe
        pipeReadHandle.readInBackgroundAndNotify()

        log.hook = { [weak self] message, level in
            guard let self else { return }

            // Use Task to handle async operations without blocking
            Task {
                await self.logWriter.writeLog(message)

                await MainActor.run {
                    self.delegate?.log(message: message)
                }
            }
        }
    }

    @objc
    func handlePipeNotification(notification: Notification) {
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify()

        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: String.Encoding.utf8)
        {
            /// write the data back into the output pipe. the output pipe's write
            /// file descriptor points to STDOUT. this allows the logs to show up
            /// on the xcode console
            outputPipe?.fileHandleForWriting.write(data)

            // Use Task to handle async operations without blocking
            Task {
                await logWriter.writeLog(str)

                await MainActor.run {
                    self.delegate?.log(message: str)
                }
            }
        }
    }

    /// Manually flush all pending log writes
    func flushLogs() {
        Task {
            await logWriter.flush()
        }
    }

    /// Cleanup resources when done
    func cleanup() {
        Task {
            await logWriter.cleanup()
        }
    }
}

// MARK: - Extensions

extension String {
    func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }

    func appendToURL(_ fileURL: URL) throws {
        if let data = data(using: .utf8) {
            try data.appendToURL(fileURL)
        }
    }
}

extension Data {
    func appendToURL(_ fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
