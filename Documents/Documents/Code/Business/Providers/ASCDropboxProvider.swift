//
//  ASCDropboxProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15.10.2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import FilesProvider
import FileKit
import Firebase

class ASCDropboxProvider: ASCBaseFileProvider {
    
    // MARK: - Properties
    
    var type: ASCFileProviderType {
        get {
            return .dropbox
        }
    }
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
    var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString("Dropbox", comment: "")
                $0.rootFolderType = .dropboxAll
                $0.id = "/"
                return $0
            }(ASCFolder())
        }
    }

    var user: ASCUser?
    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0
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
    var delegate: ASCProviderDelegate?

    private var api: ASCDropboxApi?
    internal var provider: DropboxFileProvider?
    
    fileprivate lazy var providerOperationDelegate = ASCDropboxProviderDelegate()
    private var operationProcess: Progress?
    fileprivate var operationHendlers: [(
        uid: String,
        provider: FileProviderBasic,
        progress: Progress,
        delegate: ASCDropboxProviderDelegate)] = []
    
    private let errorProviderUndefined = NSLocalizedString("Unknown file provider", comment: "")
    
    // MARK: - Lifecycle Methods
    
    init() {
        provider = nil
        api = nil
    }
    
    init(credential: URLCredential) {
        provider = DropboxFileProvider(credential: credential)
        
        api = ASCDropboxApi()
        api?.token = credential.password
    }
    
    func copy() -> ASCBaseFileProvider {
        let copy = ASCDropboxProvider()
        
        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")
        
        return copy
    }
    
    func reset() {
        cancel()

        page = 0
        total = 0
        items.removeAll()
    }
    
    func cancel() {
        api?.cancelAllTasks()
        
        operationProcess?.cancel()
        operationProcess = nil
        
        operationHendlers.forEach { handler in
            handler.progress.cancel()
        }
        operationHendlers.removeAll()
    }
    
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
                let credential = URLCredential(user: ASCConstants.Clouds.Dropbox.clientId, password: token, persistence: .forSession)
                provider = DropboxFileProvider(credential: credential)
                
                api = ASCDropboxApi()
                api?.token = credential.password
            }
        }
    }
    
    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let provider = provider else {
            let error = ASCProviderError(msg: errorProviderUndefined)
            
            DispatchQueue.main.async(execute: {
                completionHandler(false, error)
            })
            return
        }

        provider.isReachable(completionHandler: { [weak self] success, error in
            if success {
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.userInfo { success, error in
                        completionHandler(success, error)
                    }
                })
            } else {
                completionHandler(false, error)
            }
        })
    }
    
    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        api?.post(ASCDropboxApi.apiCurrentAccount) { [weak self] results, error, response in
            guard let strongSelf = self else { return }
            
            if
                error == nil,
                let result = results as? [String: Any]
            {
                strongSelf.user = ASCUser()
                strongSelf.user?.userId = result["account_id"] as? String
                strongSelf.user?.displayName = (result["name"] as? [String: Any])?["display_name"] as? String
                strongSelf.user?.department = "Dropbox"
                
                ASCFileManager.storeProviders()
                
                completeon?(true, nil)
            } else {
                completeon?(false, nil)
            }
        }
    }
    
    /// Sort records
    ///
    /// - Parameters:
    ///   - info: Sort information as dictinory
    ///   - folders: Sorted folders
    ///   - files: Sorted files
    private func sort(by info: [String: Any], folders: inout [ASCFolder], files: inout [ASCFile]) {
        let sortBy      = info["type"] as? String ?? "title"
        let sortOrder   = info["order"] as? String ?? "ascending"

        if sortBy == "title" {
            folders = sortOrder == "ascending"
                ? folders.sorted { $0.title < $1.title }
                : folders.sorted { $0.title > $1.title }
            files = sortOrder == "ascending"
                ? files.sorted { $0.title < $1.title }
                : files.sorted { $0.title > $1.title }
        } else if sortBy == "type" {
            files = sortOrder == "ascending"
                ? files.sorted { $0.title.fileExtension().lowercased() < $1.title.fileExtension().lowercased() }
                : files.sorted { $0.title.fileExtension().lowercased() > $1.title.fileExtension().lowercased() }
        } else if sortBy == "dateandtime" {
            let nowDate = Date()
            folders = sortOrder == "ascending"
                ? folders.sorted { $0.created ?? nowDate < $1.created ?? nowDate }
                : folders.sorted { $0.created ?? nowDate > $1.created ?? nowDate }
            files = sortOrder == "ascending"
                ? files.sorted { $0.updated ?? nowDate < $1.updated ?? nowDate }
                : files.sorted { $0.updated ?? nowDate > $1.updated ?? nowDate }
        } else if sortBy == "size" {
            files = sortOrder == "ascending"
                ? files.sorted { $0.pureContentLength < $1.pureContentLength }
                : files.sorted { $0.pureContentLength > $1.pureContentLength }
        }
    }

    /// Fetch an Array of 'ASCEntity's identifying the the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    func fetch(for folder: ASCFolder, parameters: [String : Any?], completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, folder, false, nil)
            return
        }

        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in
            var query = NSPredicate(format: "TRUEPREDICATE")

            // Search
            if
                let search = parameters["search"] as? [String: Any],
                let text = (search["text"] as? String)?.trim(),
                text.length > 0
            {
                query = NSPredicate(format: "(name BEGINSWITH[c] %@)", text.lowercased())
            }

            ASCBaseApi.clearCookies(for: provider.baseURL)

            provider.searchFiles(
                path: folder.id,
                recursive: false,
                query: query,
                foundItemHandler: nil)
            { [weak self] objects, error in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let strongSelf = self else { return }

                    if let error = error {
                        completeon?(strongSelf, folder, false, error)
                        return
                    }

                    if strongSelf.page == 0 {
                        strongSelf.items.removeAll()
                    }

                    var files: [ASCFile] = []
                    var folders: [ASCFolder] = []

                    folders = objects
                        .filter { $0.isDirectory && !$0.isSymLink && !$0.isHidden }
                        .map {
                            let cloudFolder = ASCFolder()
                            cloudFolder.id = $0.path
                            cloudFolder.rootFolderType = .dropboxAll
                            cloudFolder.title = $0.name
                            cloudFolder.created = $0.creationDate ?? $0.modifiedDate
                            cloudFolder.updated = $0.modifiedDate
                            cloudFolder.createdBy = strongSelf.user
                            cloudFolder.updatedBy = strongSelf.user
                            //                        cloudFolder.filesCount = -1
                            //                        cloudFolder.foldersCount = -1
                            cloudFolder.parent = folder
                            cloudFolder.parentId = folder.id

                            return cloudFolder
                    }

                    files = objects
                        .filter { !$0.isDirectory && !$0.isSymLink && !$0.isHidden }
                        .map {
                            let fileSize: UInt64 = ($0.size < 0) ? 0 : UInt64($0.size)
                            let cloudFile = ASCFile()
                            //                            file.id = $0.path
                            //                            file.title = $0.name
                            //                            file.created = $0.creationDate ?? $0.modifiedDate

                            cloudFile.id = $0.path
                            cloudFile.rootFolderType = .dropboxAll
                            cloudFile.title = $0.name
                            cloudFile.created = $0.creationDate ?? $0.modifiedDate
                            cloudFile.updated = $0.modifiedDate
                            cloudFile.createdBy = strongSelf.user
                            cloudFile.updatedBy = strongSelf.user
                            cloudFile.parent = folder
                            cloudFile.viewUrl = $0.path
                            cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                            cloudFile.pureContentLength = Int(fileSize)

                            return cloudFile
                    }

                    // Hotfix view url of media files                                        
                    let mediaFiles = files.filter { file in
                        let fileExt = file.title.fileExtension().lowercased()
                        return ASCConstants.FileExtensions.images.contains(fileExt) || ASCConstants.FileExtensions.videos.contains(fileExt)
                    }
                    
                    if mediaFiles.count > 0 {
                        let getLinkQueue = OperationQueue()
                        
                        for file in mediaFiles {
                            getLinkQueue.addOperation {
                                let semaphore = DispatchSemaphore(value: 0)

                                provider.publicLink(to: file.id) { link, fileObj, expiration, error in
                                    if let viewUrl = link?.absoluteString {
                                        files.first(where: { $0.id == file.id })?.viewUrl = viewUrl
                                    }
                                    semaphore.signal()
                                }
                                semaphore.wait()
                            }
                        }
                        
                        getLinkQueue.waitUntilAllOperationsAreFinished()
                    }
                    
                    // Sort
                    if let sortInfo = parameters["sort"] as? [String: Any] {
                        self?.sort(by: sortInfo, folders: &folders, files: &files)
                    }

                    strongSelf.items = folders as [ASCEntity] + files as [ASCEntity]
                    strongSelf.total = strongSelf.items.count

                    completeon?(strongSelf, folder, true, nil)
                })
            }
        }

        if let _ = user {
            fetch(completeon)
        } else {
            userInfo { [weak self] success, error in
                if success {
                    fetch(completeon)
                } else {
                    guard let strongSelf = self else { return }
                    completeon?(strongSelf, folder, false, error)
                }
            }
        }
    }
    
    func absoluteUrl(from string: String?) -> URL? {
        guard let urlString = string else { return nil }
        return URL(string: urlString)
    }
    
    func download(_ path: String, to destinationURL: URL, processing: @escaping ASCApiProgressHandler) {
        guard let provider = provider else {
            processing(0, nil, nil, nil)
            return
        }
        
        //        ASCBaseApi.clearCookies(for: provider.baseURL)
        
        var downloadProgress: Progress?
        
        if let localProvider = provider.copy() as? DropboxFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCDropboxProviderDelegate()
            let cleanupHendler: (String) -> Void = { [weak self] uid in
                if let processIndex = self?.operationHendlers.firstIndex(where: { $0.uid == uid }) {
                    self?.operationHendlers.remove(at: processIndex)
                }
            }
            
            operationDelegate.onSucceed = { fileProvider, operation in
                DispatchQueue.main.async {
                    processing(1.0, destinationURL, nil, nil)
                }
                cleanupHendler(handlerUid)
            }
            operationDelegate.onFailed = { fileProvider, operation, error in
                DispatchQueue.main.async {
                    processing(1.0, nil, error, nil)
                }
                cleanupHendler(handlerUid)
            }
            operationDelegate.onProgress = { fileProvider, operation, progress in
                DispatchQueue.main.async {
                    processing(Double(progress), nil, nil, nil)
                }
            }
            
            localProvider.delegate = operationDelegate
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } catch {
                log.error(error)
                processing(1.0, nil, error, nil)
                return
            }
            
            downloadProgress = localProvider.copyItem(path: path, toLocalURL: destinationURL, completionHandler: { error in
                if let error = error {
                    log.error(error.localizedDescription)
                    
                    DispatchQueue.main.async {
                        processing(1.0, nil, error, nil)
                    }
                    cleanupHendler(handlerUid)
                }
            })
            
            if let localProgress = downloadProgress {
                operationHendlers.append((
                    uid: handlerUid,
                    provider: localProvider,
                    progress: localProgress,
                    delegate: operationDelegate))
            }
        } else {
            processing(0, nil, nil, nil)
        }
    }
    
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        guard let provider = provider else {
            processing(0, nil, nil, nil)
            return
        }
        
        providerOperationDelegate.onSucceed = { [weak self] fileProvider, operation in
            self?.operationProcess = nil
            
            fileProvider.attributesOfItem(path: path, completionHandler: { fileObject, error in
                DispatchQueue.main.async(execute: { [weak self] in
                    if let error = error {
                        processing(1.0, nil, error, nil)
                    } else if let fileObject = fileObject {
                        let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)
                        
                        let parent = ASCFolder()
                        parent.id = path
                        parent.title = (path as NSString).lastPathComponent
                        
                        let cloudFile = ASCFile()
                        cloudFile.id = fileObject.path
                        cloudFile.rootFolderType = .dropboxAll
                        cloudFile.title = fileObject.name
                        cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                        cloudFile.updated = fileObject.modifiedDate
                        cloudFile.createdBy = self?.user
                        cloudFile.updatedBy = self?.user
                        cloudFile.parent = parent
                        cloudFile.viewUrl = fileObject.path
                        cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                        cloudFile.pureContentLength = Int(fileSize)
                        
                        processing(1.0, cloudFile, nil, nil)
                    } else {
                        processing(1.0, nil, nil, nil)
                    }
                })
            })
        }
        providerOperationDelegate.onFailed = { [weak self] fileProvider, operation, error in
            self?.operationProcess = nil
            DispatchQueue.main.async {
                processing(1.0, nil, error, nil)
            }
        }
        providerOperationDelegate.onProgress = { fileProvider, operation, progress in
            DispatchQueue.main.async {
                processing(Double(progress), nil, nil, nil)
            }
        }
        
        provider.delegate = providerOperationDelegate
        
        operationProcess = provider.writeContents(path: path, contents: data, overwrite: true) { error in
            log.error(error?.localizedDescription ?? "")
            DispatchQueue.main.async {
                processing(1.0, nil, error, nil)
            }
        }
    }

    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        guard let provider = provider else {
            processing(0, nil, nil, nil)
            return
        }
        
        var dstPath = path
        
        if let fileName = params?["title"] as? String {
            dstPath = (dstPath as NSString).appendingPathComponent(fileName)
        }
        
        let dummyFilePath = Path.userTemporary + UUID().uuidString
        
        do {
            try data.write(to: dummyFilePath, atomically: true)
        } catch(let error) {
            processing(1, nil, error, nil)
            return
        }
        
        var localProgress: Float = 0
        var uploadProgress: Progress?
        
        if let localProvider = provider.copy() as? DropboxFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCDropboxProviderDelegate()
            
            let cleanupHendler: (String) -> Void = { [weak self] uid in
                if let processIndex = self?.operationHendlers.firstIndex(where: { $0.uid == uid }) {
                    self?.operationHendlers.remove(at: processIndex)
                }
            }
            
            operationDelegate.onSucceed = { fileProvider, operation in
                fileProvider.attributesOfItem(path: dstPath, completionHandler: { fileObject, error in
                    DispatchQueue.main.async(execute: { [weak self] in
                        if let error = error {
                            processing(1.0, nil, error, nil)
                        } else if let fileObject = fileObject {
                            let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)
                            
                            let parent = ASCFolder()
                            parent.id = path
                            parent.title = (path as NSString).lastPathComponent
                            
                            let cloudFile = ASCFile()
                            cloudFile.id = fileObject.path
                            cloudFile.rootFolderType = .dropboxAll
                            cloudFile.title = fileObject.name
                            cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                            cloudFile.updated = fileObject.modifiedDate
                            cloudFile.createdBy = self?.user
                            cloudFile.updatedBy = self?.user
                            cloudFile.parent = parent
                            cloudFile.viewUrl = fileObject.path
                            cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                            cloudFile.pureContentLength = Int(fileSize)
                            
                            processing(1.0, cloudFile, nil, nil)
                        } else {
                            processing(1.0, nil, nil, nil)
                        }
                        ASCLocalFileHelper.shared.removeFile(dummyFilePath)
                        cleanupHendler(handlerUid)
                    })
                })
            }
            operationDelegate.onFailed = { fileProvider, operation, error in
                DispatchQueue.main.async {
                    processing(1.0, nil, error, nil)
                }
                ASCLocalFileHelper.shared.removeFile(dummyFilePath)
                cleanupHendler(handlerUid)
            }
            operationDelegate.onProgress = { fileProvider, operation, progress in
                localProgress = max(localProgress, progress)
                processing(Double(localProgress), nil, nil, nil)
            }
            
            localProvider.delegate = operationDelegate
            
            uploadProgress = localProvider.copyItem(localFile: dummyFilePath.url, to: dstPath) { error in
                if let error = error {
                    log.error(error.localizedDescription)
                    
                    DispatchQueue.main.async {
                        processing(1.0, nil, error, nil)
                    }
                    ASCLocalFileHelper.shared.removeFile(dummyFilePath)
                    cleanupHendler(handlerUid)
                }
            }
            
            if let localProgress = uploadProgress {
                operationHendlers.append((
                    uid: handlerUid,
                    provider: localProvider,
                    progress: localProgress,
                    delegate: operationDelegate))
            }
        } else {
            processing(0, nil, nil, nil)
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }
        
        let fileTitle = name + "." + fileExtension
        
        // Localize empty template
        var templateName = "empty"
        
        // Localize empty template
        if fileExtension == "xlsx" || fileExtension == "pptx" {
            let prefix = "empty-"
            var regionCode = (Locale.preferredLanguages.first ?? ASCConstants.Locale.defaultLangCode)[0..<2].uppercased()
            
            if !ASCConstants.Locale.avalibleLangCodes.contains(regionCode) {
                regionCode = ASCConstants.Locale.defaultLangCode
            }
            
            templateName = (prefix + regionCode).lowercased()
        }
        
        // Copy empty template to desination path
        if let templatePath = Bundle.main.path(forResource: templateName, ofType: fileExtension, inDirectory: "Templates") {
            let localUrl = Path(templatePath).url
            let remotePath = (Path(folder.id) + fileTitle).rawValue
            
            operationProcess = provider.copyItem(localFile: localUrl, to: remotePath) { [weak self] error in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        log.error(error.localizedDescription)
                        completeon?(strongSelf, nil, false, ASCProviderError(error))
                    } else {
                        provider.attributesOfItem(path: remotePath, completionHandler: { [weak self] fileObject, error in
                            DispatchQueue.main.async(execute: { [weak self] in
                                guard let strongSelf = self else { return }
                                
                                if let error = error {
                                    completeon?(strongSelf, nil, false, ASCProviderError(error))
                                } else if let fileObject = fileObject {
                                    let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)
                                    let cloudFile = ASCFile()
                                    cloudFile.id = fileObject.path
                                    cloudFile.rootFolderType = .dropboxAll
                                    cloudFile.title = fileObject.name
                                    cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                                    cloudFile.updated = fileObject.modifiedDate
                                    cloudFile.createdBy = strongSelf.user
                                    cloudFile.updatedBy = strongSelf.user
                                    cloudFile.parent = folder
                                    cloudFile.viewUrl = fileObject.path
                                    cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                                    cloudFile.pureContentLength = Int(fileSize)
                                    
                                    Analytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                                        "portal": strongSelf.provider?.baseURL?.absoluteString ?? "none",
                                        "onDevice": false,
                                        "type": "file",
                                        "fileExt": cloudFile.title.fileExtension().lowercased()
                                        ]
                                    )
                                    
                                    completeon?(strongSelf, cloudFile, true, nil)
                                } else {
                                    completeon?(strongSelf, nil, false, nil)
                                }
                            })
                        })
                    }
                })
            }
        }
    }

    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        let path = (Path(folder.id) + name).rawValue
        upload(path, data: data, overwrite: false, params: nil) { [weak self] progress, result, error, response in
            if let _ = result {
                Analytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": self?.provider?.baseURL?.absoluteString ?? "none",
                    "onDevice": false,
                    "type": "file",
                    "fileExt": name.fileExtension()
                    ]
                )
            }
            processing(progress, result, error, response)
        }
    }

    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }
        
        provider.create(folder: name, at: folder.id) { [weak self] error in
            DispatchQueue.main.async(execute: { [weak self] in
                guard let strongSelf = self else { return }
                
                if let error = error {
                    completeon?(strongSelf, nil, false, error)
                } else {
                    let path = (Path(folder.id) + name).rawValue
                    let nowDate = Date()

                    let cloudFolder = ASCFolder()
                    cloudFolder.id = path
                    cloudFolder.rootFolderType = .dropboxAll
                    cloudFolder.title = name
                    cloudFolder.created = nowDate
                    cloudFolder.updated = nowDate
                    cloudFolder.createdBy = strongSelf.user
                    cloudFolder.updatedBy = strongSelf.user
                    cloudFolder.parent = folder
                    cloudFolder.parentId = folder.id

                    Analytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                        "portal": provider.baseURL?.absoluteString ?? "none",
                        "onDevice": false,
                        "type": "folder"
                        ]
                    )

                    completeon?(strongSelf, cloudFolder, true, nil)
                }
            })
        }
    }
    
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }
        
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        
        if file == nil && folder == nil {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }
        
        var oldPath: Path = Path()
        var newPath: Path = Path()
        
        let entityTitle = file?.title ?? folder?.title
        
        if let file = file {
            let fileExtension = entityTitle?.fileExtension() ?? ""
            
            oldPath = Path(file.id)
            newPath = oldPath.parent + (newName + (fileExtension.length < 1 ? "" : ("." + fileExtension)))
        } else if let folder = folder {
            oldPath = Path(folder.id)
            newPath = oldPath.parent + newName
        }
        
        //        ASCBaseApi.clearCookies(for: provider.baseURL)
        
        provider.moveItem(path: oldPath.rawValue, to: newPath.rawValue, overwrite: false) { [weak self] error in
            DispatchQueue.main.async(execute: { [weak self] in
                guard let strongSelf = self else { return }
                
                if let error = error {
                    completeon?(strongSelf, nil, false, ASCProviderError(error))
                } else {                    
                    if let file = file {
                        file.id = newPath.rawValue
                        file.title = newPath.fileName
                        
                        completeon?(strongSelf, file, true, nil)
                    } else if let folder = folder {
                        folder.id = newPath.rawValue
                        folder.title = newName
                        
                        completeon?(strongSelf, folder, true, nil)
                    } else {
                        completeon?(strongSelf, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
                    }
                }
            })
        }
    }
    
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }
        
        var lastError: Error?
        var results: [ASCEntity] = []
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for entity in entities {
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                
                //                ASCBaseApi.clearCookies(for: provider.baseURL)
                
                provider.removeItem(path: entity.id, completionHandler: { error in
                    if let error = error {
                        lastError = error
                    } else {
                        results.append(entity)
                    }
                    semaphore.signal()
                })
                semaphore.wait()
            }
        }
        
        operationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async(execute: {
                completeon?(strongSelf, results, results.count > 0, lastError)
            })
        }
    }
    
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        guard let provider = provider else {
            handler?(.error, nil, ASCProviderError(msg: errorProviderUndefined).localizedDescription)
            return
        }
        
        var conflictItems: [Any] = []
        
        handler?(.begin, nil, nil)
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for entity in items {
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                let destPath = NSString(string: folder.id).appendingPathComponent(NSString(string: entity.id).lastPathComponent)
                
                //                ASCBaseApi.clearCookies(for: provider.baseURL)
                
                provider.attributesOfItem(path: destPath, completionHandler: { object, error in
                    if nil == error {
                        conflictItems.append(entity)
                    }
                    semaphore.signal()
                })
                semaphore.wait()
            }
        }
        
        operationQueue.addOperation {
            DispatchQueue.main.async(execute: {
                handler?(.end, conflictItems, nil)
            })
        }
    }
    
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) {
        var cancel = false
        
        guard let provider = provider else {
            handler?(.end, 1, nil, ASCProviderError(msg: errorProviderUndefined).localizedDescription, &cancel)
            return
        }
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        var lastError: Error?
        var results: [ASCEntity] = []
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for (index, entity) in items.enumerated() {
            operationQueue.addOperation {
                if cancel {
                    DispatchQueue.main.async(execute: {
                        handler?(.end, 1, results, lastError?.localizedDescription, &cancel)
                    })
                    return
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                let destPath = NSString(string: folder.id).appendingPathComponent(NSString(string: entity.id).lastPathComponent)
                
                //                ASCBaseApi.clearCookies(for: provider.baseURL)
                
                if move {
                    provider.moveItem(path: entity.id, to: destPath, overwrite: overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async(execute: {
                            handler?(.progress, Float(index) / Float(items.count), entity, error?.localizedDescription, &cancel)
                        })
                        semaphore.signal()
                    })
                } else {
                    provider.copyItem(path: entity.id, to: destPath, overwrite: overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async(execute: {
                            handler?(.progress, Float(index + 1) / Float(items.count), entity, error?.localizedDescription, &cancel)
                        })
                        semaphore.signal()
                    })
                }
                semaphore.wait()
            }
        }
        
        operationQueue.addOperation {
            DispatchQueue.main.async(execute: {
                if items.count == results.count {
                    handler?(.end, 1, results, nil, &cancel)
                } else {
                    handler?(.end, 1, results, lastError?.localizedDescription, &cancel)
                }
            })
        }
    }
    
    // MARK: - Access

    func allowRead(entity: AnyObject?) -> Bool {
        return true
    }
    
    func allowEdit(entity: AnyObject?) -> Bool {
        return true
    }

    func allowDelete(entity: AnyObject?) -> Bool {
        return true
    }

    func actions(for entity: ASCEntity?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let file = entity as? ASCFile {
            entityActions = actions(for: file)
        } else if let folder = entity as? ASCFolder {
            entityActions = actions(for: folder)
        }

        return entityActions
    }

    private func actions(for file: ASCFile?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let file = file {
            let fileExtension   = file.title.fileExtension().lowercased()
            let canRead         = allowRead(entity: file)
            let canEdit         = allowEdit(entity: file)
            let canDelete       = allowDelete(entity: file)
            let canOpenEditor   = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                                  ASCConstants.FileExtensions.spreadsheets.contains(fileExtension) ||
                                  ASCConstants.FileExtensions.presentations.contains(fileExtension)
            let canPreview      = canOpenEditor ||
                                  ASCConstants.FileExtensions.images.contains(fileExtension) ||
                                  fileExtension == "pdf"

            if canRead {
                entityActions.insert([.copy, .export])
            }

            if canDelete {
                entityActions.insert([.delete, .move])
            }

            if canEdit {
                entityActions.insert(.rename)
            }

            if canPreview {
                entityActions.insert(.open)
            }

            if canEdit && canOpenEditor && UIDevice.allowEditor {
                entityActions.insert(.edit)
            }
        }

        return entityActions
    }

    private func actions(for folder: ASCFolder?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let folder = folder {
            let canRead         = allowRead(entity: folder)
            let canEdit         = allowEdit(entity: folder)
            let canDelete       = allowDelete(entity: folder)

            if canEdit {
                entityActions.insert(.rename)
            }

            if canRead {
                entityActions.insert(.copy)
            }

            if canEdit && canDelete {
                entityActions.insert(.move)
            }

            if canDelete {
                entityActions.insert(.delete)
            }
        }

        return entityActions
    }

    // MARK: - Open file

    func open(file: ASCFile, viewMode: Bool = false) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let allowOpen       = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if allowOpen {
            let editMode = !viewMode && UIDevice.allowEditor
            let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
            let closeHandler = delegate?.closeProgressFile(title: NSLocalizedString("Saving", comment: "Caption of the processing"))

            ASCEditorManager.shared.editFileLocally(for: self, file, viewMode: !editMode, handler: openHandler, closeHandler: closeHandler)
        }
    }

    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let isPdf           = fileExt == "pdf"
        let isImage         = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo         = ASCConstants.FileExtensions.videos.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            ASCEditorManager.shared.browsePdfCloud(for: self, file, handler: openHandler)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else {
            if let view = view {
                let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }

}


// MARK: - FileProvider Delegate

class ASCDropboxProviderDelegate: FileProviderDelegate {
    var onSucceed:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType) -> Void)?
    var onFailed:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ error: Error) -> Void)?
    var onProgress:((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ progress: Float) -> Void)?

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
