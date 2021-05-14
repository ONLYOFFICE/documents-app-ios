//
//  ASCOneDriveProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import FilesProvider
import FileKit

class ASCOneDriveProvider {
    // MARK: - ASCFileProviderProtocol variables
    var delegate: ASCProviderDelegate?
    var user: ASCUser?
    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0
    
    private var api: ASCOneDriveApi?

    private var provider: OneDriveFileProvider?
    
    fileprivate var operationHendlers: [(
        uid: String,
        provider: FileProviderBasic,
        progress: Progress,
        delegate: FileProviderDelegate)] = []
    
    private var operationProcess: Progress?
    
    private let errorProviderUndefined = NSLocalizedString("Unknown file provider", comment: "")
    
    init() {
        provider = nil
        api = nil
    }
    
    init(credential: URLCredential) {
        provider = ASCOneDriveFileProvider(credential: credential)
        api = ASCOneDriveApi()
        api?.token = credential.password
    }
    
    private func makeCloudFile(from file: FileObject) -> ASCFile {
        let fileSize: UInt64 = (file.size < 0) ? 0 : UInt64(file.size)
        let cloudFile = ASCFile()
        if let oneDriveItem = file as? OneDriveFileObject, let id = oneDriveItem.id {
            cloudFile.id = id
            cloudFile.viewUrl = "id:\(id)"
        } else {
            cloudFile.id = file.path
            cloudFile.viewUrl = file.path
        }
        cloudFile.rootFolderType = .onedriveAll
        cloudFile.title = file.name
        cloudFile.created = file.creationDate ?? file.modifiedDate
        cloudFile.updated = file.modifiedDate
        cloudFile.createdBy = self.user
        cloudFile.updatedBy = self.user
        cloudFile.parent = folder
        cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
        cloudFile.pureContentLength = Int(fileSize)

        return cloudFile
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
                $0.id = ""
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
        let copy = ASCOneDriveProvider()
        
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
    
    func fetch(for folder: ASCFolder, parameters: [String : Any?], completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, folder, false, nil)
            return
        }

        self.folder = folder
        
        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in

            ASCBaseApi.clearCookies(for: provider.baseURL)

            provider.contentsOfDirectory(path: folder.id)
            { [weak self] objects, error in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let self = self else { return }

                    if let error = error {
                        completeon?(self, folder, false, error)
                        return
                    }

                    if self.page == 0 {
                        self.items.removeAll()
                    }

                    var files: [ASCFile] = []
                    var folders: [ASCFolder] = []

                    folders = objects
                        .filter { $0.isDirectory && !$0.isSymLink && !$0.isHidden }
                        .map {
                            let cloudFolder = ASCFolder()
                            if let oneDriveItem = $0 as? OneDriveFileObject, let id = oneDriveItem.id {
                                cloudFolder.id = "id:\(id)"
                            } else {
                                cloudFolder.id = $0.path
                            }
                            cloudFolder.rootFolderType = .onedriveAll
                            cloudFolder.title = $0.name
                            cloudFolder.created = $0.creationDate ?? $0.modifiedDate
                            cloudFolder.updated = $0.modifiedDate
                            cloudFolder.createdBy = self.user
                            cloudFolder.updatedBy = self.user
                            cloudFolder.parent = folder
                            cloudFolder.parentId = folder.id

                            return cloudFolder
                    }

                    files = objects
                        .filter { !$0.isDirectory && !$0.isSymLink && !$0.isHidden }
                        .map { return self.makeCloudFile(from: $0) }

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
                    self.fetchInfo = parameters
                    
                    if let sortInfo = parameters["sort"] as? [String: Any] {
                        self.sort(by: sortInfo, folders: &folders, files: &files)
                    }

                    self.items = folders as [ASCEntity] + files as [ASCEntity]
                    self.total = self.items.count

                    completeon?(self, folder, true, nil)
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
    
    func add(item: ASCEntity, at index: Int) {
        if !items.contains(where: { $0.uid == item.uid }) {
            items.insert(item, at: index)
            total += 1
        }
    }
    
    func add(items: [ASCEntity], at index: Int) {
        let uniqItems = items.filter { (item) -> Bool in
            return !self.items.contains(where: { $0.uid == item.uid })
        }
        self.items.insert(contentsOf: uniqItems, at: index)
        self.total += uniqItems.count
    }
    
    func remove(at index: Int) {
        items.remove(at: index)
        total -= 1
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
    
    func cancel() {
        api?.cancelAllTasks()
    }
    
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
    
    func download(_ path: String, to destinationURL: URL, processing: @escaping ASCApiProgressHandler) {
        guard let provider = provider as? ASCOneDriveFileProvider else {
            processing(0, nil, nil, nil)
            return
        }

        var downloadProgress: Progress?
        
        if let localProvider = provider.copy() as? OneDriveFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCOneDriveProviderDelegate()
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
        
        if let localProvider = provider.copy() as? OneDriveFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCOneDriveProviderDelegate()
            
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
                            
                            let parent = ASCFolder()
                            if let oneDriveItem = fileObject as? OneDriveFileObject, let id = oneDriveItem.id {
                                parent.id = "id:\(id)"
                            } else {
                                parent.id = path
                            }
                            parent.title = (path as NSString).lastPathComponent
                            
                            let cloudFile = self?.makeCloudFile(from: fileObject)
                            
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
    
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {}
    
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {}
    
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
                provider.removeItem(path: "id:\(entity.id)", completionHandler: { error in
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
            guard let self = self else { return }
            
            DispatchQueue.main.async(execute: {
                completeon?(self, results, results.count > 0, lastError)
            })
        }
    }
    
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }
        
        let fileTitle = name + "." + fileExtension
        
        // Copy empty template to desination path
        if let templatePath = ASCFileManager.documentTemplatePath(with: fileExtension) {
            let localUrl = Path(templatePath).url
            
            let remotePath = folder.id.contains("id:") ? "\(folder.id):/\(fileTitle):/" : (Path(folder.id) + fileTitle).rawValue
            
            operationProcess = provider.copyItem(localFile: localUrl, to: remotePath) { [weak self] error in
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let self = self else { return }
                    if let error = error {
                        log.error(error.localizedDescription)
                        completeon?(self, nil, false, ASCProviderError(error))
                    } else {
                        provider.attributesOfItem(path: remotePath, completionHandler: { [weak self] fileObject, error in
                            DispatchQueue.main.async(execute: { [weak self] in
                                guard let self = self else { return }
                                
                                if let error = error {
                                    completeon?(self, nil, false, ASCProviderError(error))
                                } else if let fileObject = fileObject {
                                    
                                    let cloudFile = self.makeCloudFile(from: fileObject)
                                    
                                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                                        "portal": self.provider?.baseURL?.absoluteString ?? "none",
                                        "onDevice": false,
                                        "type": "file",
                                        "fileExt": cloudFile.title.fileExtension().lowercased()
                                        ]
                                    )
                                    
                                    completeon?(self, cloudFile, true, nil)
                                } else {
                                    completeon?(self, nil, false, nil)
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
        let path = folder.id.contains("id:") ? "\(folder.id):/\(name):/" : (Path(folder.id) + name).rawValue
        upload(path, data: data, overwrite: false, params: nil) { [weak self] progress, result, error, response in
            if let _ = result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
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
                    cloudFolder.rootFolderType = .onedriveAll
                    cloudFolder.title = name
                    cloudFolder.created = nowDate
                    cloudFolder.updated = nowDate
                    cloudFolder.createdBy = strongSelf.user
                    cloudFolder.updatedBy = strongSelf.user
                    cloudFolder.parent = folder
                    cloudFolder.parentId = folder.id

                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
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
    
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?) { handler?(.end, nil, nil) }
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) { var cancel = false; handler?(.end, 1, nil, nil, &cancel) }

    func allowRead(entity: AnyObject?) -> Bool { return true }
    func allowEdit(entity: AnyObject?) -> Bool { return true }
    func allowDelete(entity: AnyObject?) -> Bool { return true }
    
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
    
    func preview(file: ASCFile, files: [ASCFile]? = nil, in view: UIView? = nil) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let isPdf           = fileExt == "pdf"
        let isImage         = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo         = ASCConstants.FileExtensions.videos.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            ASCEditorManager.shared.browsePdfCloud(for: self, file, handler: openHandler)
        } else if isImage || isVideo {
            file.viewUrl = provider?.url(of: file.viewUrl ?? "", modifier: "content").absoluteString ?? file.viewUrl
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else {
            if let view = view {
                let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }
    
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

class ASCOneDriveProviderDelegate: FileProviderDelegate {
    // MARK: - FileProviderDelegate variables
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
