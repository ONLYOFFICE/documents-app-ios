//
//  ASCWebDAVProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FileKit
import FilesProvider
import Firebase
import UIKit

class ASCWebDAVProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {
    // MARK: - Properties

    var type: ASCFileProviderType {
        return .webdav
    }

    var id: String? {
        if
            let provider = provider,
            let credential = provider.credential,
            let baseUrl = provider.baseURL?.absoluteString,
            let userId = credential.user,
            let password = credential.password
        {
            return (baseUrl + password + userId).md5
        }

        return nil
    }

    var items: [ASCEntity] = []
    var page: Int = 0
    var pageSize: Int = 20
    var total: Int = 0
    var user: ASCUser?
    var authorization: String? {
        guard
            let provider = provider,
            let credential = provider.credential,
            let user = credential.user,
            let password = credential.password,
            let credentialData = "\(user):\(password)".data(using: .utf8)
        else { return nil }

        let base64Credentials = credentialData.base64EncodedData(options: [])
        if let base64Date = Data(base64Encoded: base64Credentials) {
            return "Basic \(base64Date.base64EncodedString())"
        }

        return nil
    }

    var rootFolder: ASCFolder {
        return {
            $0.title = NSLocalizedString("WebDAV", comment: "")
            $0.rootFolderType = .webdavAll
            $0.id = "/"
            return $0
        }(ASCFolder())
    }

    var delegate: ASCProviderDelegate?
    var filterController: ASCFiltersControllerProtocol?

    var provider: WebDAVFileProvider?

    var folder: ASCFolder?
    var fetchInfo: [String: Any?]?

    fileprivate lazy var providerOperationDelegate = ASCWebDAVProviderDelegate()
    private var operationProcess: Progress?
    fileprivate var operationHendlers: [(
        uid: String,
        provider: FileProviderBasic,
        progress: Progress,
        delegate: ASCWebDAVProviderDelegate
    )] = []

    private let errorProviderUndefined = NSLocalizedString("Unknown file provider", comment: "")

    // MARK: - Lifecycle Methods

    init() {
        provider = nil
        user = nil
    }

    init(baseURL: URL, credential: URLCredential) {
        var providerUrl = baseURL

        if providerUrl.scheme == nil,
           let fixedUrl = URL(string: "https://\(providerUrl.absoluteString)")
        {
            providerUrl = fixedUrl
        }

        provider = WebDAVFileProvider(baseURL: providerUrl, credential: credential)
        provider?.credentialType = .basic

        user = ASCUser()
        user?.userId = credential.user
        user?.displayName = credential.user
        user?.department = providerUrl.host
    }

    func copy() -> ASCFileProviderProtocol {
        let copy = ASCWebDAVProvider()

        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")

        return copy
    }

    func reset() {
        page = 0
        total = 0
        items.removeAll()
    }

    func cancel() {
        operationProcess?.cancel()
        operationProcess = nil

        for handler in operationHendlers {
            handler.progress.cancel()
        }
        operationHendlers.removeAll()
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue,
        ]

        if let baseUrl = provider?.baseURL?.absoluteString {
            info += ["baseUrl": baseUrl.hasSuffix("/") ? baseUrl.dropLast() : baseUrl]
        }

        if let password = provider?.credential?.password {
            info += ["password": password]
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

            if
                let baseUrl = URL(string: json["baseUrl"] as? String ?? ""),
                let password = json["password"] as? String,
                let user = user,
                let userId = user.userId
            {
                let credential = URLCredential(user: userId, password: password, persistence: .permanent)

                provider = WebDAVFileProvider(baseURL: baseUrl, credential: credential)
                provider?.credentialType = .basic
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
        let uniqItems = items.filter { item -> Bool in
            !self.items.contains(where: { $0.uid == item.uid })
        }
        self.items.insert(contentsOf: uniqItems, at: index)
        total += uniqItems.count
    }

    func remove(at index: Int) {
        items.remove(at: index)
        total -= 1
    }

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let provider = provider else {
            let error = ASCProviderError(msg: errorProviderUndefined)

            DispatchQueue.main.async {
                completionHandler(false, error)
            }
            return
        }

//        ASCBaseApi.clearCookies(for: provider.baseURL)

        provider.isReachable(completionHandler: { success, error in
            DispatchQueue.main.async {
                completionHandler(success, error)
            }
        })
    }

    func isReachable(
        with info: [String: Any],
        complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)
    ) {
        guard
            let portal = info["url"] as? String,
            let login = info["login"] as? String,
            let password = info["password"] as? String,
            let portalUrl = URL(string: portal)
        else {
            complation(false, nil)
            return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let webDavProvider = ASCWebDAVProvider(baseURL: portalUrl, credential: credential)
        let rootFolder: ASCFolder = {
            $0.title = NSLocalizedString("All Files", comment: "Category title")
            $0.rootFolderType = .webdavAll
            $0.id = "/"
            return $0
        }(ASCFolder())

        webDavProvider.fetch(for: rootFolder, parameters: [:]) { provider, folder, success, error in
            DispatchQueue.main.async {
                complation(success, success ? webDavProvider : nil)
            }
        }
    }

    /// Sort records
    ///
    /// - Parameters:
    ///   - completeon: a closure with result of sort entries or error
    func updateSort(completeon: ASCProviderCompletionHandler?) {
        if let sortInfo = fetchInfo?["sort"] as? [String: Any] {
            sort(by: sortInfo, entities: &items)
            total = items.count
        }
        completeon?(self, folder, true, nil)
    }

    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        completeon?(true, nil)
    }

    /// Fetch an Array of 'ASCEntity's identifying the the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, folder, false, nil)
            return
        }

        self.folder = folder

        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in
            var query = NSPredicate(format: "TRUEPREDICATE")

            // Search
            if
                let search = parameters["search"] as? [String: Any],
                let text = (search["text"] as? String)?.trimmed,
                text.length > 0
            {
                query = NSPredicate(format: "(name CONTAINS[cd] %@)", text.lowercased())
            }

            NetworkingClient.clearCookies(for: provider.baseURL)

            provider.searchFiles(
                path: folder.id,
                recursive: false,
                query: query,
                foundItemHandler: nil
            ) { [weak self] objects, error in
                DispatchQueue.main.async { [weak self] in
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
                            cloudFolder.rootFolderType = .nextcloudAll
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
                            cloudFile.rootFolderType = .nextcloudAll
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

                    // Sort
                    strongSelf.fetchInfo = parameters

                    if let sortInfo = parameters["sort"] as? [String: Any] {
                        self?.sort(by: sortInfo, folders: &folders, files: &files)
                    }

                    strongSelf.items = folders as [ASCEntity] + files as [ASCEntity]
                    strongSelf.total = strongSelf.items.count

                    completeon?(strongSelf, folder, true, nil)
                }
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
        return provider?.url(of: string ?? "")
    }

    func download(_ path: String, to destinationURL: URL, range: Range<Int64>? = nil, processing: @escaping NetworkProgressHandler) {
        guard let provider else {
            processing(nil, 0, nil)
            return
        }

        var downloadProgress: Progress?

        if let localProvider = provider.copy() as? WebDAVFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCWebDAVProviderDelegate()

            let cleanupHendler: (String) -> Void = { [weak self] uid in
                if let processIndex = self?.operationHendlers.firstIndex(where: { $0.uid == uid }) {
                    self?.operationHendlers.remove(at: processIndex)
                }
            }

            operationDelegate.onSucceed = { fileProvider, operation in
                DispatchQueue.main.async {
                    processing(destinationURL, 1.0, nil)
                }
                cleanupHendler(handlerUid)
            }
            operationDelegate.onFailed = { fileProvider, operation, error in
                DispatchQueue.main.async {
                    processing(nil, 1.0, error)
                }
                cleanupHendler(handlerUid)
            }
            operationDelegate.onProgress = { fileProvider, operation, progress in
                DispatchQueue.main.async {
                    processing(nil, Double(progress), nil)
                }
            }

            localProvider.delegate = operationDelegate

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } catch {
                log.error(error)
                processing(nil, 1.0, error)
                return
            }

            downloadProgress = localProvider.copyItem(path: path, toLocalURL: destinationURL, completionHandler: { error in
                if let error = error {
                    log.error(error.localizedDescription)

                    DispatchQueue.main.async {
                        processing(nil, 1.0, error)
                    }
                    cleanupHendler(handlerUid)
                }
            })

            if let localProgress = downloadProgress {
                operationHendlers.append((
                    uid: handlerUid,
                    provider: localProvider,
                    progress: localProgress,
                    delegate: operationDelegate
                ))
            }
        } else {
            processing(nil, 0, nil)
        }
    }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
            return
        }

//        ASCBaseApi.clearCookies(for: provider.baseURL)

        providerOperationDelegate.onSucceed = { [weak self] fileProvider, operation in
            self?.operationProcess = nil

            fileProvider.attributesOfItem(path: path, completionHandler: { fileObject, error in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        processing(nil, 1.0, error)
                    } else if let fileObject = fileObject {
                        let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)

                        let parent = ASCFolder()
                        parent.id = path
                        parent.title = (path as NSString).lastPathComponent

                        let cloudFile = ASCFile()
                        cloudFile.id = fileObject.path
                        cloudFile.rootFolderType = .nextcloudAll
                        cloudFile.title = fileObject.name
                        cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                        cloudFile.updated = fileObject.modifiedDate
                        cloudFile.createdBy = self?.user
                        cloudFile.updatedBy = self?.user
                        cloudFile.parent = parent
                        cloudFile.viewUrl = fileObject.path
                        cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                        cloudFile.pureContentLength = Int(fileSize)

                        processing(cloudFile, 1.0, nil)
                    } else {
                        processing(nil, 1.0, nil)
                    }
                }
            })
        }
        providerOperationDelegate.onFailed = { [weak self] fileProvider, operation, error in
            self?.operationProcess = nil
            DispatchQueue.main.async {
                processing(nil, 1.0, error)
            }
        }
        providerOperationDelegate.onProgress = { fileProvider, operation, progress in
            DispatchQueue.main.async {
                processing(nil, Double(progress), nil)
            }
        }

        provider.delegate = providerOperationDelegate

        operationProcess = provider.writeContents(path: path, contents: data, overwrite: true) { error in
            log.error(error?.localizedDescription ?? "")
            DispatchQueue.main.async {
                processing(nil, 1.0, error)
            }
        }
    }

    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
            return
        }

//        ASCBaseApi.clearCookies(for: provider.baseURL)

        var dstPath = path

        if let fileName = params?["title"] as? String {
            dstPath = (dstPath as NSString).appendingPathComponent(fileName)
        }

        let dummyFilePath = Path.userTemporary + UUID().uuidString

        do {
            try data.write(to: dummyFilePath, atomically: true)
        } catch {
            processing(nil, 1, error)
            return
        }

        var localProgress: Float = 0
        var uploadProgress: Progress?

        if let localProvider = provider.copy() as? WebDAVFileProvider {
            let handlerUid = UUID().uuidString
            let operationDelegate = ASCWebDAVProviderDelegate()

            let cleanupHendler: (String) -> Void = { [weak self] uid in
                if let processIndex = self?.operationHendlers.firstIndex(where: { $0.uid == uid }) {
                    self?.operationHendlers.remove(at: processIndex)
                }
            }

            operationDelegate.onSucceed = { fileProvider, operation in
                fileProvider.attributesOfItem(path: dstPath, completionHandler: { fileObject, error in
                    DispatchQueue.main.async { [weak self] in
                        if let error = error {
                            processing(nil, 1.0, error)
                        } else if let fileObject = fileObject {
                            let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)

                            let parent = ASCFolder()
                            parent.id = path
                            parent.title = (path as NSString).lastPathComponent

                            let cloudFile = ASCFile()
                            cloudFile.id = fileObject.path
                            cloudFile.rootFolderType = .nextcloudAll
                            cloudFile.title = fileObject.name
                            cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                            cloudFile.updated = fileObject.modifiedDate
                            cloudFile.createdBy = self?.user
                            cloudFile.updatedBy = self?.user
                            cloudFile.parent = parent
                            cloudFile.viewUrl = fileObject.path
                            cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                            cloudFile.pureContentLength = Int(fileSize)

                            processing(cloudFile, 1.0, nil)
                        } else {
                            processing(nil, 1.0, nil)
                        }
                        ASCLocalFileHelper.shared.removeFile(dummyFilePath)
                        cleanupHendler(handlerUid)
                    }
                })
            }
            operationDelegate.onFailed = { fileProvider, operation, error in
                DispatchQueue.main.async {
                    processing(nil, 1.0, error)
                }
                ASCLocalFileHelper.shared.removeFile(dummyFilePath)
                cleanupHendler(handlerUid)
            }
            operationDelegate.onProgress = { fileProvider, operation, progress in
                localProgress = max(localProgress, progress)
                processing(nil, Double(localProgress), nil)
            }

            localProvider.delegate = operationDelegate

            uploadProgress = localProvider.copyItem(localFile: dummyFilePath.url, to: dstPath) { error in
                if let error = error {
                    log.error(error.localizedDescription)

                    DispatchQueue.main.async {
                        processing(nil, 1.0, error)
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
                    delegate: operationDelegate
                ))
            }
        } else {
            processing(nil, 0, nil)
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }

//        ASCBaseApi.clearCookies(for: provider.baseURL)

        let fileTitle = name + "." + fileExtension

        // Copy empty template to desination path
        if let templatePath = ASCFileManager.documentTemplatePath(with: fileExtension) {
            let localUrl = Path(templatePath).url
            let remotePath = (Path(folder.id) + fileTitle).rawValue

            operationProcess = provider.copyItem(localFile: localUrl, to: remotePath) { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        log.error(error.localizedDescription)
                        completeon?(strongSelf, nil, false, ASCProviderError(error))
                    } else {
                        provider.attributesOfItem(path: remotePath, completionHandler: { [weak self] fileObject, error in
                            DispatchQueue.main.async { [weak self] in
                                guard let strongSelf = self else { return }

                                if let error = error {
                                    completeon?(strongSelf, nil, false, ASCProviderError(error))
                                } else if let fileObject = fileObject {
                                    let fileSize: UInt64 = (fileObject.size < 0) ? 0 : UInt64(fileObject.size)
                                    let cloudFile = ASCFile()
                                    cloudFile.id = fileObject.path
                                    cloudFile.rootFolderType = .nextcloudAll
                                    cloudFile.title = fileObject.name
                                    cloudFile.created = fileObject.creationDate ?? fileObject.modifiedDate
                                    cloudFile.updated = fileObject.modifiedDate
                                    cloudFile.createdBy = strongSelf.user
                                    cloudFile.updatedBy = strongSelf.user
                                    cloudFile.parent = folder
                                    cloudFile.viewUrl = fileObject.path
                                    cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                                    cloudFile.pureContentLength = Int(fileSize)

                                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                                        ASCAnalytics.Event.Key.portal: strongSelf.provider?.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                                        ASCAnalytics.Event.Key.onDevice: false,
                                        ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                                        ASCAnalytics.Event.Key.fileExt: cloudFile.title.fileExtension().lowercased(),
                                    ])

                                    completeon?(strongSelf, cloudFile, true, nil)
                                } else {
                                    completeon?(strongSelf, nil, false, nil)
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        let path = (Path(folder.id) + name).rawValue
        upload(path, data: data, overwrite: false, params: nil) { [weak self] result, progress, error in
            if let _ = result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: self?.provider?.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                    ASCAnalytics.Event.Key.fileExt: name.fileExtension(),
                ])
            }
            processing(result, progress, error)
        }
    }

    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }

//        ASCBaseApi.clearCookies(for: provider.baseURL)

        provider.create(folder: name, at: folder.id) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                if let error = error {
                    completeon?(strongSelf, nil, false, error)
                } else {
                    let path = (Path(folder.id) + name).rawValue
                    let nowDate = Date()

                    let cloudFolder = ASCFolder()
                    cloudFolder.id = path
                    cloudFolder.rootFolderType = .nextcloudAll
                    cloudFolder.title = name
                    cloudFolder.created = nowDate
                    cloudFolder.updated = nowDate
                    cloudFolder.createdBy = strongSelf.user
                    cloudFolder.updatedBy = strongSelf.user
                    cloudFolder.parent = folder
                    cloudFolder.parentId = folder.id

                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                        ASCAnalytics.Event.Key.portal: provider.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                        ASCAnalytics.Event.Key.onDevice: false,
                        ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.folder,
                    ])

                    completeon?(strongSelf, cloudFolder, true, nil)
                }
            }
        }
    }

    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }

        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil, folder == nil {
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
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                if let error = error {
                    completeon?(strongSelf, nil, false, ASCProviderError(error))
                } else {
                    if let file = file {
                        file.id = newPath.rawValue
                        file.title = newPath.fileName
                        file.viewUrl = newPath.rawValue

                        completeon?(strongSelf, file, true, nil)
                    } else if let folder = folder {
                        folder.id = newPath.rawValue
                        folder.title = newName

                        completeon?(strongSelf, folder, true, nil)
                    } else {
                        completeon?(strongSelf, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
                    }
                }
            }
        }
    }

    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?) {
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

            DispatchQueue.main.async {
                completeon?(strongSelf, results, results.count > 0, lastError)
            }
        }
    }

    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        guard let provider = provider else {
            handler?(.error, nil, ASCProviderError(msg: errorProviderUndefined))
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
                    if error == nil {
                        conflictItems.append(entity)
                    }
                    semaphore.signal()
                })
                semaphore.wait()
            }
        }

        operationQueue.addOperation {
            DispatchQueue.main.async {
                handler?(.end, conflictItems, nil)
            }
        }
    }

    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, conflictResolveType: ConflictResolveType, contentOnly: Bool, handler: ASCEntityProgressHandler?) {
        var cancel = false

        let overwrite = conflictResolveType == .overwrite
        guard let provider = provider else {
            handler?(.end, 1, nil, ASCProviderError(msg: errorProviderUndefined), &cancel)
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
                    DispatchQueue.main.async {
                        handler?(.end, 1, results, lastError, &cancel)
                    }
                    return
                }

                let semaphore = DispatchSemaphore(value: 0)
                let destPath = NSString(string: folder.id).appendingPathComponent(NSString(string: entity.id).lastPathComponent)

//                ASCBaseApi.clearCookies(for: provider.baseURL)

                if move {
                    provider.moveItem(path: entity.id, to: destPath, overwrite: conflictResolveType == .overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async {
                            handler?(.progress, Float(index) / Float(items.count), entity, error, &cancel)
                        }
                        semaphore.signal()
                    })
                } else {
                    provider.copyItem(path: entity.id, to: destPath, overwrite: conflictResolveType == .overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async {
                            handler?(.progress, Float(index + 1) / Float(items.count), entity, error, &cancel)
                        }
                        semaphore.signal()
                    })
                }
                semaphore.wait()
            }
        }

        operationQueue.addOperation {
            DispatchQueue.main.async {
                if items.count == results.count {
                    handler?(.end, 1, results, nil, &cancel)
                } else {
                    handler?(.end, 1, results, lastError, &cancel)
                }
            }
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
            let fileExtension = file.title.fileExtension().lowercased()
            let canRead = allowRead(entity: file)
            let canEdit = allowEdit(entity: file)
            let canDelete = allowDelete(entity: file)
            let canOpenEditor = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                ASCConstants.FileExtensions.spreadsheets.contains(fileExtension) ||
                ASCConstants.FileExtensions.presentations.contains(fileExtension) ||
                ASCConstants.FileExtensions.forms.contains(fileExtension)
            let canPreview = canOpenEditor ||
                ASCConstants.FileExtensions.images.contains(fileExtension) ||
                fileExtension == ASCConstants.FileExtensions.pdf

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

            if canEdit, canOpenEditor, UIDevice.allowEditor {
                entityActions.insert(.edit)
            }
        }

        return entityActions
    }

    private func actions(for folder: ASCFolder?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let folder = folder {
            let canRead = allowRead(entity: folder)
            let canEdit = allowEdit(entity: folder)
            let canDelete = allowDelete(entity: folder)

            if canRead, canEdit {
                entityActions.insert(.open)
            }

            if canEdit {
                entityActions.insert(.rename)
            }

            if canRead {
                entityActions.insert(.copy)
            }

            if canEdit, canDelete {
                entityActions.insert(.move)
            }

            if canDelete {
                entityActions.insert(.delete)
            }
        }

        return entityActions
    }

    // MARK: - Open file

    func open(file: ASCFile, openMode: ASCDocumentOpenMode, canEdit: Bool) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let allowOpen = ASCConstants.FileExtensions.allowEdit.contains(fileExt)
        let isForm = ([ASCConstants.FileExtensions.pdf] + ASCConstants.FileExtensions.forms).contains(fileExt)

        if allowOpen || isForm {
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
            let closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))
            let renameHandler: ASCEditorManagerRenameHandler = { file, title, complation in
                guard let file = file else { complation(false); return }

                self.rename(file, to: title) { provider, result, success, error in
                    if let file = result as? ASCFile {
                        complation(file.title.fileName() == title)
                    } else {
                        complation(false)
                    }
                }
            }

            ASCEditorManager.shared.editFileLocally(
                for: self,
                file,
                openMode: openMode,
                canEdit: canEdit && UIDevice.allowEditor,
                handler: openHandler,
                closeHandler: closeHandler,
                renameHandler: renameHandler
            )
        }
    }

    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isPdf = fileExt == ASCConstants.FileExtensions.pdf
        let isImage = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo = ASCConstants.FileExtensions.videos.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            let closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))
            ASCEditorManager.shared.browsePdfCloud(for: self, file, openHandler: openHandler, closeHandler: closeHandler)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else {
            if let view = view {
                let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }
}

// MARK: - FileProvider Delegate

class ASCWebDAVProviderDelegate: FileProviderDelegate {
    var onSucceed: ((_ fileProvider: FileProviderOperations, _ operation: FileOperationType) -> Void)?
    var onFailed: ((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ error: Error) -> Void)?
    var onProgress: ((_ fileProvider: FileProviderOperations, _ operation: FileOperationType, _ progress: Float) -> Void)?

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
