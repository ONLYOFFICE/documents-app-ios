//
//  ASCDocumentService.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/3/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire
import FileKit
import SwiftyXMLParser

enum ASCDocumentServiceStatus: String {
    case begin     = "ASCDocumentServiceBegin"
    case progress  = "ASCDocumentServiceProgress"
    case end       = "ASCDocumentServiceEnd"
    case error     = "ASCDocumentServiceError"
}

typealias ASCDocumentServiceHandler = (_ status: ASCEditorManagerStatus, _ progress: Float, _ result: Any?, _ error: String?, _ cancel: inout Bool) -> Void

class ASCDocumentServiceKey {
    
    private let ascKey      = ASCConstants.Keys.ascDocumentServiceKey
    private let ascKeyId    = ASCConstants.Keys.ascDocumentServiceKeyId
    
    // MARK: - Public
    
    func key(by documentId: String) -> String {
        var currentDate = internalTime()
        
        if currentDate == nil {
           currentDate = Date()
        }
        
        let dictionaryKeys: [String: Any] = [
            "expire"    : timeJson(from: currentDate!),
            "key"       : documentId,
            "key_id"    : ascKeyId,
            "user_count": 0
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionaryKeys, options: .prettyPrinted)
            if  let string = String(data: jsonData, encoding: String.Encoding.utf8),
                let hash = base64(string: "\(string)\(ascKey)") {
                    let payload = "\(hash)?\(string)"
                    return urlTockenEncode(source: payload)
                }
        } catch {
            log.error("ASCDocumentServiceKey error serializing JSON: \(error)")
        }
        return ""
    }
    
    // MARK: - Private
    
    private func urlTockenEncode(source: String) -> String {
        if let plainData = source.data(using: String.Encoding.utf8) {
            var base64String = plainData.base64EncodedString()
            let requiredLength = Int(4 * ceil(Double(base64String.length) / 4.0))
            let nbrPaddings = requiredLength - base64String.length
            
            if nbrPaddings > 0 {
                let padding = "".padding(toLength: nbrPaddings, withPad: "=", startingAt: 0)
                base64String = base64String.appending(padding)
            }
            
            base64String = base64String.replacingOccurrences(of: "-", with: "+")
            base64String = base64String.replacingOccurrences(of: "_", with: "/")
            base64String = "\(base64String)0"
            
            return base64String
        }
        
        return ""
    }
    
    private func internalTime() -> Date? {
        if let reachability = NetworkReachabilityManager(host: "http://google.com"), reachability.isReachable {
            var date: Date?
            
            // Syncronize Alamofire request
            let sem = DispatchSemaphore(value: 0)
            
            AF.request("http://google.com")
                .responseJSON(queue: DispatchQueue.global(qos: .userInitiated)) { response in
                if let fields = response.response?.allHeaderFields as? [String: Any] {
                    // print("\(fields)")
                    
                    if let value = fields["Date"] as? String {
                        let formatter = DateFormatter()
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.timeZone = TimeZone(secondsFromGMT: 0)
                        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ssZZZ"
                        
                        date = formatter.date(from: value)
                        sem.signal()
                    }
                }
            }
            
            sem.wait()
            
            return date
        }
        
        return nil
    }
    
    private func timeJson(from date: Date) -> String {
        let gmtTimeInterval = date.timeIntervalSinceReferenceDate
        let gmtDate = Date.init(timeIntervalSinceReferenceDate: gmtTimeInterval)
        return "/Date(\(Int64(gmtDate.timeIntervalSince1970 * 1000)))/"
    }
    
    private func base64(string: String) -> String? {
        if let hash = sha256(string: string) {
            return hash.base64EncodedString()
        }
        return nil
    }
    
    private func sha256(string: String) -> Data? {
        guard let messageData = string.data(using: String.Encoding.utf8) else { return nil; }
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }

}

@available(*, deprecated, message: "Online conversion service is no longer available. Use a local converter.")
class ASCDocumentService {
    private var documentServiceDomain: String = ASCConstants.Urls.documentServiceDomain
    private var documentServiceUri: String = ""
    private var documentUploadUri: String = ""
    private var documentShareUri: String = ""
    private var processHandler: ASCDocumentServiceHandler?
    private var inputFormat: String = ""
    private var outputFormat: String = ""
    private var fileTitle: String = ""
    
    // MARK: - Public
    
    @available(*, deprecated, message: "Online conversion service is no longer available. Use a local converter.")
    init() {
        documentServiceDomain = ASCConstants.Urls.documentServiceDomain
        documentServiceUri = "https://\(documentServiceDomain)/ConvertService.ashx"
        documentUploadUri  = "https://\(documentServiceDomain)/FileUploader.ashx"
    }
    
    /// Convert a local file through an online conversion service
    /// - Parameters:
    ///   - file: The file to be converted.
    ///   - fromFormat: Input conversion format.
    ///   - toFormat: Output conversion format.
    ///   - handler: Online conversion handler.
    @available(*, deprecated, message: "Online conversion service is no longer available. Use a local converter.")
    func convertationLocal(_ file: ASCFile, fromFormat: String, toFormat: String, handler: ASCDocumentServiceHandler?) {
        var cancel = false
        
        processHandler = handler
        inputFormat = fromFormat
        outputFormat = toFormat
        fileTitle = file.title
        
        processHandler?(.begin, 0.3, nil, nil, &cancel)
        
        let dataFile = DataFile(path: Path(file.id))
        var content: Data?
        
        do {
            content = try dataFile.read()
        } catch {
            processHandler?(.error, 1, nil, NSLocalizedString("Could not read data from file.", comment: ""), &cancel)
            return
        }
        
        if let fileContent = content {
            createUploadFileLink(data: fileContent)
        } else {
            processHandler?(.error, 1, nil, NSLocalizedString("Empty file.", comment: ""), &cancel)
        }
    }
    
    /// Convert a cloud file through an online conversion service
    /// - Parameters:
    ///   - file: The file to be converted.
    ///   - fromFormat: Input conversion format.
    ///   - toFormat: Output conversion format.
    ///   - handler: Online conversion handler.
    @available(*, deprecated, message: "Online conversion service is no longer available. Use a local converter.")
    func convertationCloud(_ file: ASCFile, fromFormat: String, toFormat: String, handler: ASCDocumentServiceHandler?) {
        var cancel = false
        
        guard
            OnlyofficeApiClient.shared.active,
            let viewUrl = file.viewUrl
        else {
            processHandler?(.end, 0, nil, nil, &cancel)
            return
        }
        
        processHandler = handler
        inputFormat = fromFormat
        outputFormat = toFormat
        fileTitle = file.title
        documentShareUri = file.id
        
        processHandler?(.begin, 0, nil, nil, &cancel)
        
        let destinationPath = Path.userTemporary + Path(fileTitle.fileName() + "_original." + fileTitle.fileExtension())
        let destinationUrl = URL(fileURLWithPath:destinationPath.rawValue)
        
        let destination: DownloadRequest.Destination = { url, respons in
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        }

        if let downloadUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: viewUrl)) {
            let request = AF.download(downloadUrl, to: destination)
            
            request
                .downloadProgress { progress in // main queue by default
                    self.processHandler?(.progress, Float(0.3 * progress.fractionCompleted), nil, nil, &cancel)

                    if cancel {
                        request.cancel()
                        self.processHandler?(.end, 1, nil, nil, &cancel)
                    }
                }
                .responseData { response in
                    DispatchQueue.main.async(execute: {
                        if let _ = response.error {
                            self.processHandler?(.error, 1, nil, NSLocalizedString("Failure to download file from portal.", comment: ""), &cancel)
                        } else if let _ = response.value {
                            let dataFile = DataFile(path: destinationPath)
                            var content: Data?

                            do {
                                content = try dataFile.read()
                            } catch {
                                self.processHandler?(.error, 1, nil, NSLocalizedString("Could not read data from file.", comment: ""), &cancel)
                                return
                            }

                            if let fileContent = content {
                                self.createUploadFileLink(data: fileContent)
                            } else {
                                self.processHandler?(.error, 1, nil, NSLocalizedString("Empty file.", comment: ""), &cancel)
                            }
                        }
                    })
            }
        }
    }
    
    
    // MARK: - Private
    
    private func createUploadFileLink(data: Data) {
        let vKey = ASCDocumentServiceKey()
        let documentId = uuid()
        let postLength = "\(data.count)"
        let urlString  = String(format:"%@?key=%@&vkey=%@", documentUploadUri, documentId, vKey.key(by: documentId))
        
        let headers: HTTPHeaders = [
            "Content-Length": postLength,
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        var cancel = false
        
        let request = AF.upload(data, to: urlString, method: .post, headers: headers)
            
        request
            .uploadProgress { progress in // main queue by default
                self.processHandler?(.progress, 0.3 + Float(0.3 * progress.fractionCompleted), nil, nil, &cancel)
                
                if cancel {
                    request.cancel()
                    self.processHandler?(.end, 1, nil, nil, &cancel)
                }
            }
            .responseData { response in
                DispatchQueue.main.async(execute: {
                    if let error = response.error {
                        self.processHandler?(.error, 1, nil, NSLocalizedString("Failed upload source file to conversion online service.", comment: ""), &cancel)
                        log.error(error)
                    } else if let data = response.data {
                        let xml = XML.parse(data)
                        let fileUrl = xml["FileResult", "FileUrl"]
                        
                        if case .failure(let error) = fileUrl {
                            self.processHandler?(.error, 1, nil, NSLocalizedString("Unexpected response from the service.", comment: ""), &cancel)
                            log.error(error)
                            return
                        }
                        
                        if let fileUrl = fileUrl.text, fileUrl.length > 0 {
                            self.documentShareUri = fileUrl
                            self.processHandler?(.progress, 0.6, nil, nil, &cancel)
                            self.convertFileWithOnlineService()
                        } else {
                            self.processHandler?(.error, 1, nil, NSLocalizedString("Unexpected response from the service.", comment: ""), &cancel)
                        }
                    } else {
                        self.processHandler?(.error, 1, nil, NSLocalizedString("Failed upload source file to conversion online service.", comment: ""), &cancel)
                    }
                })
            }
    }
    
    private func convertFileWithOnlineService() {
        let vKey = ASCDocumentServiceKey()
        let documentId = uuid()

        var cancel = false
        
        let parameters: Parameters = [
            "url": documentShareUri,
            "outputtype": outputFormat,
            "filetype": inputFormat,
            "key": documentId,
            "vkey": vKey.key(by: documentId)
        ]
        
        AF.request(documentServiceUri, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseData { response in
                DispatchQueue.main.async(execute: {
                    if let error = response.error {
                        self.processHandler?(.error, 1, nil, NSLocalizedString("Failed online conversion service.", comment: ""), &cancel)
                        log.error(error)
                    } else if let data = response.data {
                        let xml = XML.parse(data)
                        let fileUrl = xml["FileResult", "FileUrl"]
                        
                        if case .failure(let error) = fileUrl {
                            self.processHandler?(.error, 1, nil, NSLocalizedString("Unexpected response from the service.", comment: ""), &cancel)
                            log.error(error)
                            return
                        }
                        
                        if let fileUrl = fileUrl.text, fileUrl.length > 0, let url = URL(string: fileUrl) {
                            self.downloadResultFileData(url: url)
                        } else {
                            self.processHandler?(.error, 1, nil, NSLocalizedString("Unexpected response from the service.", comment: ""), &cancel)
                        }
                    } else {
                        self.processHandler?(.error, 1, nil, NSLocalizedString("Failed online conversion service.", comment: ""), &cancel)
                    }
                })
        }
    }
    
    private func downloadResultFileData(url: URL) {
        var cancel = false
        self.processHandler?(.progress, 0.6, nil, nil, &cancel)
        
        let destinationPath = Path.userTemporary + Path(fileTitle.fileName() + "." + outputFormat)
        let destinationUrl = URL(fileURLWithPath:destinationPath.rawValue)
        
        let destination: DownloadRequest.Destination = { url, respons in
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let request = AF.download(url, to: destination)
        
        request
            .downloadProgress { progress in // main queue by default
                self.processHandler?(.progress, 0.6 + Float(0.4 * progress.fractionCompleted), nil, nil, &cancel)
                
                if cancel {
                    request.cancel()
                    self.processHandler?(.end, 1, nil, nil, &cancel)
                }
            }
            .responseData { response in
                DispatchQueue.main.async(execute: {
                    if let _ = response.error {
                        self.processHandler?(.error, 1, nil, NSLocalizedString("Failure to download result from conversion online service.", comment: ""), &cancel)
                    } else if let _ = response.value {
                        let resultFile = ASCFile()
                        resultFile.id = destinationPath.rawValue
                        resultFile.title = self.fileTitle
                        resultFile.device = true
                        
                        // Cleanup temporary file from cloud
                        let originalFilePath = Path.userTemporary + (self.fileTitle.fileName() + "_original." + self.fileTitle.fileExtension())
                        if originalFilePath.exists {
                            ASCLocalFileHelper.shared.removeFile(originalFilePath)
                        }
                        
                        self.processHandler?(.end, 1, resultFile, nil, &cancel)
                    }
                })
        }
    }
    
    private func uuid() -> String {
        return "ios_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
