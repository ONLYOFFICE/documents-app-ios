//
//  ASCOneDriveFileProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import FilesProvider

class ASCOneDriveFileProvider: OneDriveFileProvider {
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        var serverURL = self.baseURL
        if serverURL?.lastPathComponent == OneDriveFileProvider.graphVersion {
            serverURL?.deleteLastPathComponent()
        }
        let copy = OneDriveFileProvider(credential: self.credential, serverURL: serverURL, route: self.route, cache: self.cache)
        copy.delegate = self.delegate
        copy.fileOperationDelegate = self.fileOperationDelegate
        copy.useCache = self.useCache
        copy.validatingCache = self.validatingCache
        return copy
    }
    
    open override func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        var request = URLRequest(url: url(of: ""))
        request.httpMethod = "Get"
        request.setValue(authentication: credential, with: .oAuth2)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 400
            if status >= 400, let code = FileProviderHTTPErrorCode(rawValue: status) {
                let errorDesc = data.flatMap({ String(data: $0, encoding: .utf8) })
                let error = FileProviderOneDriveError(code: code, path: "", serverDescription: errorDesc)
                completionHandler(false, error)
                return
            }
            completionHandler(status == 200, error)
        })
        task.resume()
    }
    
    
    /**
     Returns a `FileObject` containing the attributes of the item (file, directory, symlink, etc.) at the path in question via asynchronous completion handler.
     
     If the directory contains no entries or an error is occured, this method will return the empty `FileObject`.
     
     - Parameters:
     - path: path to target directory. If empty, attributes of root will be returned.
     - completionHandler: a closure with result of directory entries or error.
     - attributes: A `FileObject` containing the attributes of the item.
     - error: Error returned by system.
     */
    func attributesOfItem(folderId: String, fileName: String, completionHandler: @escaping (_ attributes: FileObject?, _ error: Error?) -> Void) {
        var components = URLComponents(url: url(of: folderId, modifier: "children"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "filter", value: "name eq '\(fileName)'")]
        guard let url = components?.url else {
            completionHandler(nil, URLError(.badURL))
            return
        }
        
        var request = URLRequest(url: url)
                                          
        request.httpMethod = "GET"
        request.setValue(authentication: self.credential, with: .oAuth2)
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            var serverError: FileProviderOneDriveError?
            if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
                let code = FileProviderHTTPErrorCode(rawValue: response.statusCode)
                serverError = code.flatMap { FileProviderOneDriveError(code: $0, path: url.absoluteString, serverDescription: error?.localizedDescription) }
                completionHandler(nil, serverError)
                return
            }
            
            guard let json = self.deserializeJSON(data: data), let entries = json["value"] as? [Any] else {
                let err = URLError(.badServerResponse, userInfo: ["reason": "deserialization faild"])
                completionHandler(nil, err)
                return
            }
            
            var files = [FileObject]()
            for entry in entries {
                
                if let entry = entry as? [String: Any],
                   let name = entry["name"] as? String,
                   let id = entry["id"] as? String
                {
                    let hashes = (json["file"] as? [String: Any])?["hashes"] as? [String: Any]
                    let allValues: [URLResourceKey: Any] = [
                        .fileResourceIdentifierKey: id,
                        .nameKey: name,
                        .pathKey: "id:\(id)",
                        .childrensCount: (entry["folder"] as? [String: Any])?["childCount"] as? Int ?? 0,
                        .attributeModificationDateKey: (entry["lastModifiedDateTime"] as? String).flatMap { Date(rfcString: $0) } ?? "",
                        .creationDateKey: (entry["createdDateTime"] as? String).flatMap { Date(rfcString: $0) } ?? "",
                        .fileResourceTypeKey: entry["folder"] != nil ? URLFileResourceType.directory : URLFileResourceType.regular,
                        .mimeTypeKey: ((entry["file"] as? [String: Any])?["mimeType"] as? String).flatMap(ContentMIMEType.init(rawValue:)) ?? .stream,
                        .entryTagKey: entry["eTag"] as? String ?? "",
                        .documentIdentifierKey: (hashes?["sha1Hash"] as? String) ?? (hashes?["quickXorHash"] as? String) ?? "",
                        .fileSizeKey: (entry["size"] as? NSNumber)?.int64Value ?? -1,
                    ]
                    let file = FileObject(allValues: allValues)
                    
                    files.append(file)
                }
            }
            
            guard files.count == 1 else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(files.first, error)
        })
        task.resume()
    }
    
    override func moveItem(path: String, to toPath: String, overwrite: Bool, completionHandler: SimpleCompletionHandler) -> Progress? {
        return self.moveItem(path: path, to: toPath, overwrite: overwrite, requestData: [:], completionHandler: completionHandler)
    }
    
    func moveItem(path: String, to toPath: String, overwrite: Bool,  requestData: [String: Any], completionHandler: SimpleCompletionHandler) -> Progress? {
        let url = super.url(of: path, modifier: "")
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authentication: self.credential, with: .oAuth2)
        
        var requestData = requestData
        
        if !toPath.isEmpty {
            requestData["parentReference"] = toPath.hasPrefix("id")
                ? ["id"  : toPath.removingPrefix("id:")]
                : ["path": toPath]
        }
        if overwrite {
            requestData["@microsoft.graph.conflictBehavior"] = "replace"
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: requestData)
        request.httpBody = jsonData
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler?(error)
        })
        task.resume()
        
        return nil
    }
    
    override func copyItem(path: String, to toPath: String, overwrite: Bool, completionHandler: SimpleCompletionHandler) -> Progress? {
        
        let url = super.url(of: path, modifier: "copy")
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authentication: self.credential, with: .oAuth2)
        
        var requestData: [String: Any] = [:]

        requestData["parentReference"] = toPath.hasPrefix("id")
            ? ["id"  : toPath.removingPrefix("id:")]
            : ["path": toPath]
            
        if overwrite {
            requestData["@microsoft.graph.conflictBehavior"] = "replace"
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: requestData)
        request.httpBody = jsonData
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler?(error)
        })
        task.resume()
        
        return nil
    }
    
    private func deserializeJSON(data: Data?) -> [String: Any]? {
        guard let data = data else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }
}

internal extension URLRequest {
    mutating func setValue(authentication credential: URLCredential?, with type: AuthenticationType) {
        func base64(_ str: String) -> String {
            let plainData = str.data(using: .utf8)
            let base64String = plainData!.base64EncodedString(options: [])
            return base64String
        }
        
        guard let credential = credential else { return }
        switch type {
        case .basic:
            let user = credential.user?.replacingOccurrences(of: ":", with: "") ?? ""
            let pass = credential.password ?? ""
            let authStr = "\(user):\(pass)"
            if let base64Auth = authStr.data(using: .utf8)?.base64EncodedString() {
                self.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
            }
        case .digest:
            // handled by RemoteSessionDelegate
            break
        case .oAuth1:
            if let oauth = credential.password {
                self.setValue("OAuth \(oauth)", forHTTPHeaderField: "Authorization")
            }
        case .oAuth2:
            if let bearer = credential.password {
                self.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
            }
        }
    }
}

internal struct FileProviderOneDriveError: FileProviderHTTPError {
    public let code: FileProviderHTTPErrorCode
    public let path: String
    public let serverDescription: String?
}
