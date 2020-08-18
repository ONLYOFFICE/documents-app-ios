//
//  ASCLogIntercepter.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCLogInterceptorDelegate: class {
    func log(message: String)
}

class ASCLogIntercepter {
    public static let shared = ASCLogIntercepter()
    
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private let queue = DispatchQueue(label: "asc.log.interceptor.queue", qos: .default, attributes: .concurrent)
    
    weak var delegate: ASCLogInterceptorDelegate?
    var logUrl: URL? {
        get {
            if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                let documentsDirectory = URL(fileURLWithPath: path)
                return documentsDirectory.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app")-output.log")
            }
            return nil
        }
    }
    
    public func start() {
        if let logUrl = logUrl {
            /// Cleanup
            do {
                try "".write(to: logUrl, atomically: true, encoding: .utf8)
            } catch {}
        }
        
        openConsolePipe()
    }
    
    private func openConsolePipe() {
        
        //open a new Pipe to consume the messages on STDOUT and STDERR
        inputPipe = Pipe()
        
        //open another Pipe to output messages back to STDOUT
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

        //listen in to the readHandle notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handlePipeNotification),
            name: FileHandle.readCompletionNotification,
            object: pipeReadHandle
        )

        //state that you want to be notified of any data coming across the pipe
        pipeReadHandle.readInBackgroundAndNotify()
    }
    
    @objc
    func handlePipeNotification(notification: Notification) {
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify()
        
        if  let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
            let str = String(data: data, encoding: String.Encoding.utf8),
            let logUrl = logUrl
        {
            
            /// write the data back into the output pipe. the output pipe's write
            /// file descriptor points to STDOUT. this allows the logs to show up
            /// on the xcode console
            outputPipe?.fileHandleForWriting.write(data)
            
            queue.async(flags: .barrier) {
                do {
                    try str.appendLineToURL(logUrl)
                } catch {}
            }

            delegate?.log(message: str)
        }
    }
}

extension String {
    func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }

    func appendToURL(_ fileURL: URL) throws {
        if let data = self.data(using: .utf8) {
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
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
