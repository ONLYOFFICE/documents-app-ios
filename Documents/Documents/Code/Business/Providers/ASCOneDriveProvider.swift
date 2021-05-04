//
//  ASCOneDriveProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import FilesProvider

class ASCOneDriveProvider {
    // MARK: - ASCFileProviderProtocol variables
    var delegate: ASCProviderDelegate?
    var user: ASCUser?
    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0
    
    // MARK: - FileProviderDelegate variables
    var onSucceed:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType) -> Void)?
    var onFailed:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ error: Error) -> Void)?
    var onProgress:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ progress: Float) -> Void)?
    
    private var api: ASCOneDriveApi?

    private var provider: OneDriveFileProvider?
    
    init() {
        provider = nil
        api = nil
    }
    
    init(credential: URLCredential) {
        provider = ASCOneDriveFileProvider(credential: credential)
        api = ASCOneDriveApi()
        api?.token = credential.password
    }
}

// MARK: - ASCFileProviderProtocol

extension ASCOneDriveProvider: ASCFileProviderProtocol {
    var id: String? {
        get {
            if
                let provider = provider,
                let credential = provider.credential,
                let password = credential.password
            {
                return (String(describing: self) + password).md5
            }
            return nil
        }
    }
    
    var type: ASCFileProviderType {
        return .onedrive
    }
    
    var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString("OneDrive", comment: "")
                $0.rootFolderType = .onedriveAll
                $0.id = "/"
                return $0
            }(ASCFolder())
        }
    }
   
    
    var authorization: String? {
        get {
            guard
                let provider = provider,
                let credential = provider.credential,
                let token = credential.password
            else { return nil }
            return "Bearer \(token)"
        }
    }

    
    func copy() -> ASCFileProviderProtocol {
        let copy = ASCDropboxProvider()
        
        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")
        
        return copy

    }
    
    func reset() {
        
    }
    
    func fetch(for folder: ASCFolder, parameters: [String : Any?], completeon: ASCProviderCompletionHandler?) {
        
    }
    
    func add(item: ASCEntity, at index: Int) {
        
    }
    
    func add(items: [ASCEntity], at index: Int) {
        
    }
    
    func remove(at index: Int) {
        
    }
    
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        api?.get("", completion: { [weak self] (json, error, response) in
            guard let self = self, error == nil, let json = json as? [String: Any] else {
                completeon?(false, error)
                return
            }
            
            let user = ASCUser(JSON: json)
            user?.department = "OneDrive"
            self.user = user
            
            ASCFileManager.storeProviders()
            
            completeon?(true, nil)
        })
    }
    
    func cancel() {}
    func updateSort(completeon: ASCProviderCompletionHandler?) {}
    
    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue
        ]

        if let token = provider?.credential?.password {
            info += ["token": token]
        }
        
        if let user = user {
            info += ["user": user.toJSON()]
        } else {
            let user = ASCUser()
            user.userId = provider?.credential?.user
            user.displayName = user.userId
            info += ["user": user.toJSON()]
        }

        if let id = id {
            info += ["id": id]
        }

        return info.jsonString()
    }
    
    func deserialize(_ jsonString: String) {
        if let json = jsonString.toDictionary() {
            if let userJson = json["user"] as? [String: Any] {
                user = ASCUser(JSON: userJson)
            }
            
            if let token = json["token"] as? String {
                let credential = URLCredential(user: ASCConstants.Clouds.OneDrive.clientId, password: token, persistence: .forSession)
                provider = ASCOneDriveFileProvider(credential: credential)
                api = ASCOneDriveApi()
                api?.token = credential.password
            }
        }
    }
    
    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let provider = provider else {
            let error = ASCProviderError(msg: "errorProviderUndefined")
            
            DispatchQueue.main.async(execute: {
                completionHandler(false, error)
            })
            return
        }

        provider.isReachable(completionHandler: { [self] success, error in
            if success {
                DispatchQueue.main.async(execute: { [self] in
                    self.userInfo { success, error in
                        completionHandler(success, error)
                    }
                })
            } else {
                completionHandler(false, error)
            }
        })
    }
    func absoluteUrl(from string: String?) -> URL? { return URL(string: string ?? "") }
    func errorMessage(by errorObject: Any) -> String  { return "" }
    func handleNetworkError(_ error: Error?) -> Bool { return false }
    func modifyImageDownloader(request: URLRequest) -> URLRequest { return request }
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler) {}
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {}
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {}
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {}
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {}
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {}
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {}
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?) { handler?(.end, nil, nil) }
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) { var cancel = false; handler?(.end, 1, nil, nil, &cancel) }

    func allowRead(entity: AnyObject?) -> Bool { return false }
    func allowEdit(entity: AnyObject?) -> Bool { return false }
    func allowDelete(entity: AnyObject?) -> Bool { return false }
    func actions(for entity: ASCEntity?) -> ASCEntityActions { return [] }
    func open(file: ASCFile, viewMode: Bool = false) {}
    func preview(file: ASCFile, files: [ASCFile]? = nil, in view: UIView? = nil) {}
    
}

// MARK: - ASCSortableFileProviderProtocol

extension ASCOneDriveProvider: ASCSortableFileProviderProtocol {
    var folder: ASCFolder? {
        get {
            return nil
        }
        set {
            
        }
    }
    
    var fetchInfo: [String : Any?]? {
        get {
            return nil
        }
        set {
            
        }
    }
    
}

// MARK: - FileProviderDelegate

extension ASCOneDriveProvider: FileProviderDelegate {

    func fileproviderSucceed(_ fileProvider: FileProviderOperations, operation: FileOperationType) {
        log.info("\(String(describing: fileProvider)): \(operation) - Success")
        fileProvider.delegate = nil
        onSucceed?(fileProvider, operation)
    }

    func fileproviderFailed(_ fileProvider: FileProviderOperations, operation: FileOperationType, error: Error) {
        log.error("\(String(describing: fileProvider)): \(operation) - Failed")
        fileProvider.delegate = nil
        onFailed?(fileProvider, operation, error)
    }

    func fileproviderProgress(_ fileProvider: FileProviderOperations, operation: FileOperationType, progress: Float) {
        log.debug("\(String(describing: fileProvider)): \(operation) - Progress: \(progress * 100)")
        onProgress?(fileProvider, operation, progress)
    }
}
