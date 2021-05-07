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
