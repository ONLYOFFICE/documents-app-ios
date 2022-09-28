//
//  ASCOneDriveProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import FileKit
import FilesProvider
import Foundation

class ASCOneDriveProvider: ASCSortableFileProviderProtocol {
    // MARK: - ASCSortableFileProviderProtocol variables

    internal var folder: ASCFolder?
    internal var fetchInfo: [String: Any?]?

    // MARK: - ASCFileProviderProtocol variables

    var filterController: ASCFiltersControllerProtocol?
    var delegate: ASCProviderDelegate?
    var user: ASCUser?
    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0

    private var apiClient: OnedriveApiClient?
    public var provider: ASCOneDriveFileProvider? {
        didSet {
            guard let provider = provider else {
                entityExistenceChecker = nil
                entityUniqNameFinder = nil
                return
            }

            entityExistenceChecker = ASCEntityExistenceCheckerByAttributes(provider: provider)
            entityUniqNameFinder = ASCEntityUniqNameFinder(entityExistChecker: entityExistenceChecker!)
        }
    }

    private var entityExistenceChecker: ASCEntityExistenceChecker?
    private var entityUniqNameFinder: ASCUniqNameFinder?

    fileprivate lazy var providerOperationDelegate = ASCOneDriveProviderDelegate()

    fileprivate var operationHendlers: [(
        uid: String,
        provider: FileProviderBasic,
        progress: Progress,
        delegate: FileProviderDelegate
    )] = []

    private var operationProcess: Progress?

    private let errorProviderUndefined = NSLocalizedString("Unknown file provider", comment: "")

    init() {
        provider = nil
        apiClient = nil
    }

    init(urlCredential: URLCredential, oAuthCredential: ASCOAuthCredential) {
        provider = ASCOneDriveFileProvider(credential: urlCredential)
        apiClient = OnedriveApiClient()
        apiClient?.credential = oAuthCredential
        apiClient?.onRefreshToken = { [weak self] credential in
            self?.provider?.credential = URLCredential(
                user: ASCConstants.Clouds.OneDrive.clientId,
                password: credential.accessToken,
                persistence: .forSession
            )
        }
    }

    private func makeCloudFile(from file: FileObject) -> ASCFile {
        let fileSize: UInt64 = (file.size < 0) ? 0 : UInt64(file.size)
        let cloudFile = ASCFile()
        if let oneDriveItem = file as? OneDriveFileObject, let id = oneDriveItem.id {
            cloudFile.id = "id:\(id)"
            cloudFile.viewUrl = "id:\(id)"
        } else {
            cloudFile.id = file.path
            cloudFile.viewUrl = file.path
        }
        cloudFile.rootFolderType = .onedriveAll
        cloudFile.title = file.name
        cloudFile.created = file.creationDate ?? file.modifiedDate
        cloudFile.updated = file.modifiedDate
        cloudFile.createdBy = user
        cloudFile.updatedBy = user
        cloudFile.parent = folder
        cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
        cloudFile.pureContentLength = Int(fileSize)

        return cloudFile
    }
}

// MARK: - ASCFileProviderProtocol

extension ASCOneDriveProvider: ASCFileProviderProtocol {
    var id: String? {
        if let user = user {
            return user.userId
        }
        return nil
    }

    var type: ASCFileProviderType {
        return .onedrive
    }

    var rootFolder: ASCFolder {
        return {
            $0.title = NSLocalizedString("OneDrive", comment: "")
            $0.rootFolderType = .onedriveAll
            $0.id = ""
            return $0
        }(ASCFolder())
    }

    var authorization: String? {
        guard
            let provider = provider,
            let credential = provider.credential,
            let token = credential.password
        else { return nil }
        return "Bearer \(token)"
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

    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, folder, false, nil)
            return
        }

        self.folder = folder

        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in

            NetworkingClient.clearCookies(for: provider.baseURL)

            provider.contentsOfDirectory(path: folder.id) { [weak self] objects, error in
                DispatchQueue.main.async { [weak self] in
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
                        .map { self.makeCloudFile(from: $0) }

                    let mediaFiles = files.filter { file in
                        let fileExt = file.title.fileExtension().lowercased()
                        return ASCConstants.FileExtensions.images.contains(fileExt) || ASCConstants.FileExtensions.videos.contains(fileExt)
                    }

                    if mediaFiles.count > 0 {
                        let getLinkQueue = OperationQueue()

                        for file in mediaFiles {
                            getLinkQueue.addOperation {
                                files.first(where: { $0.id == file.id })?.viewUrl =
                                    provider.url(of: file.viewUrl ?? "", modifier: "content").absoluteString
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
                }
            }
        }

        if user == nil || apiClient?.credential?.requiresRefresh ?? false {
            userInfo { [weak self] success, error in
                if success {
                    fetch(completeon)
                } else {
                    guard let strongSelf = self else { return }
                    completeon?(strongSelf, folder, false, error)
                }
            }
        } else {
            fetch(completeon)
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

    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        apiClient?.request(OnedriveAPI.Endpoints.me) { response, error in
            if let error = error {
                log.error(error)
                completeon?(false, error)
                return
            }

            if let user = response {
                user.department = "OneDrive"
                self.user = user

                ASCFileManager.storeProviders()
            }

            completeon?(true, nil)
        }
    }

    func cancel() {
        apiClient?.cancelAll()

        operationProcess?.cancel()
        operationProcess = nil

        operationHendlers.forEach { handler in
            handler.progress.cancel()
        }
        operationHendlers.removeAll()
    }

    func updateSort(completeon: ASCProviderCompletionHandler?) {
        if let sortInfo = fetchInfo?["sort"] as? [String: Any] {
            sort(by: sortInfo, entities: &items)
            total = items.count
        }
        completeon?(self, folder, true, nil)
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue,
        ]

        if let authCredential = apiClient?.credential {
            info += ["accessToken": authCredential.accessToken]
            info += ["refreshToken": authCredential.refreshToken]
            info += ["expiration": authCredential.expiration.timeIntervalSince1970]
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

            if let accessToken = json["accessToken"] as? String,
               let refreshToken = json["refreshToken"] as? String,
               let expiration = json["expiration"] as? Double
            {
                let oAuthCredential = ASCOAuthCredential(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiration: Date(timeIntervalSince1970: expiration)
                )
                let urlCredential = URLCredential(
                    user: ASCConstants.Clouds.OneDrive.clientId,
                    password: oAuthCredential.accessToken,
                    persistence: .forSession
                )

                provider = ASCOneDriveFileProvider(credential: urlCredential)

                apiClient = OnedriveApiClient()
                apiClient?.credential = oAuthCredential
                apiClient?.onRefreshToken = { [weak self] credential in
                    self?.provider?.credential = URLCredential(
                        user: ASCConstants.Clouds.OneDrive.clientId,
                        password: credential.accessToken,
                        persistence: .forSession
                    )
                }
            }
        }
    }

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let provider = provider else {
            let error = ASCProviderError(msg: "errorProviderUndefined")

            DispatchQueue.main.async {
                completionHandler(false, error)
            }
            return
        }

        provider.isReachable(completionHandler: { [self] success, error in
            if success {
                DispatchQueue.main.async { [self] in
                    self.userInfo { success, error in
                        completionHandler(success, error)
                    }
                }
            } else {
                completionHandler(false, error)
            }
        })
    }

    func isReachable(with info: [String: Any], complation: @escaping ((Bool, ASCFileProviderProtocol?) -> Void)) {
        guard
            let accessToken = info["token"] as? String,
            let refreshToken = info["refresh_token"] as? String,
            let expiration = info["expires_in"] as? Int
        else {
            complation(false, nil)
            return
        }

        let urlCredential = URLCredential(user: ASCConstants.Clouds.OneDrive.clientId, password: accessToken, persistence: .forSession)
        let oAuthCredential = ASCOAuthCredential(accessToken: accessToken, refreshToken: refreshToken, expiration: Date().adding(.second, value: expiration))
        let onedriveCloudProvider = ASCOneDriveProvider(urlCredential: urlCredential, oAuthCredential: oAuthCredential)

        onedriveCloudProvider.isReachable { success, error in
            DispatchQueue.main.async {
                complation(success, success ? onedriveCloudProvider : nil)
            }
        }
    }

    func absoluteUrl(from string: String?) -> URL? { return URL(string: string ?? "") }
    func errorMessage(by errorObject: Any) -> String { return "" }
    func handleNetworkError(_ error: Error?) -> Bool { return false }
    func modifyImageDownloader(request: URLRequest) -> URLRequest { return request }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
            return
        }

        providerOperationDelegate.onSucceed = { [weak self] fileProvider, operation in
            self?.operationProcess = nil

            fileProvider.attributesOfItem(path: "id:\(path)", completionHandler: { fileObject, error in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        processing(nil, 1.0, error)
                    } else if let fileObject = fileObject {
                        let cloudFile = self?.makeCloudFile(from: fileObject)

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

        operationProcess = provider.writeContents(path: "id:\(path)", contents: data, overwrite: true) { error in
            log.error(error?.localizedDescription ?? "")
            DispatchQueue.main.async {
                processing(nil, 1.0, error)
            }
        }
    }

    func download(_ path: String, to destinationURL: URL, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
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

    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
            return
        }

        var dstPath = path

        if let fileName = params?["title"] as? String {
            if !dstPath.isEmpty {
                dstPath = (dstPath as NSString)
                    .appending(":")
                    .appendingPathComponent(fileName)
                    .appending(":")
            } else {
                dstPath = (dstPath as NSString)
                    .appendingPathComponent(fileName)
            }
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
                    DispatchQueue.main.async { [weak self] in
                        if let error = error {
                            processing(nil, 1.0, error)
                        } else if let fileObject = fileObject {
                            let cloudFile = self?.makeCloudFile(from: fileObject)

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

        var entityId: String = ""
        var entityName: String = ""

        let entityTitle = file?.title ?? folder?.title

        if let file = file {
            let fileExtension = entityTitle?.fileExtension() ?? ""
            entityId = file.id
            entityName = newName + (fileExtension.length < 1 ? "" : ("." + fileExtension))
        } else if let folder = folder {
            entityId = folder.id
            entityName = newName
        }

        let moveItemFunc = {
            log.info("moving")
            _ = provider.moveItem(path: entityId, to: "", overwrite: false, requestData: ["name": entityName]) { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    guard error == nil else {
                        completeon?(self, nil, false, ASCProviderError(error!))
                        return
                    }

                    if let file = file {
                        file.title = entityName

                        completeon?(self, file, true, nil)
                    } else if let folder = folder {
                        folder.title = entityName

                        completeon?(self, folder, true, nil)
                    } else {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
                    }
                }
            }
        }

        let entityPathDefineCompletion: (String?, Error?) -> Void = { path, error in
            guard let path = path, !path.isEmpty, error == nil else {
                if error != nil {
                    log.error(error!.localizedDescription)
                }
                moveItemFunc()
                return
            }

            let fullPath = path.deletingLastPathComponent.appendingPathComponent(entityName)

            log.info("Getting item attributes by path: \(fullPath)")
            provider.attributesOfItem(path: fullPath) { entityObject, error in
                guard error == nil else {
                    log.error(error!.localizedDescription)
                    moveItemFunc()
                    return
                }

                guard entityObject == nil else {
                    DispatchQueue.main.async {
                        completeon?(self, entity, false, ASCProviderError(msg: NSLocalizedString("Rename failed. An object with such a similar name exists.", comment: "")))
                    }
                    return
                }

                log.info("Attributes not found. Can move.")
                moveItemFunc()
            }
        }

        log.info("Definding path")
        if let folder = entity as? ASCFolder, folder.id.isEmpty {
            entityPathDefineCompletion("/".appendingPathComponent(folder.title), nil)
        } else {
            provider.pathOfItem(withId: entityId, completionHandler: entityPathDefineCompletion)
        }
    }

    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {}

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

            DispatchQueue.main.async {
                completeon?(self, results, results.count > 0, lastError)
            }
        }
    }

    func findUniqName(suggestedName: String, inFolder folder: ASCFolder, completionHandler: @escaping (String) -> Void) {
        guard let provider = provider, let entityUniqNameFinder = entityUniqNameFinder else {
            completionHandler(suggestedName)
            return
        }

        let pathFoundCompletion: (String?, Error?) -> Void = { path, error in
            guard error == nil, let folderPath = path else {
                completionHandler(suggestedName)
                return
            }

            entityUniqNameFinder.find(bySuggestedName: suggestedName, atPath: folderPath) { uniqName in
                completionHandler(uniqName)
            }
        }

        if folder.id.isEmpty {
            pathFoundCompletion("/", nil)
        } else {
            provider.pathOfItem(withId: folder.id, completionHandler: pathFoundCompletion)
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }

        let fileTitle = name + "." + fileExtension

        findUniqName(suggestedName: fileTitle, inFolder: folder) { fileTitle in
            let file = ASCFile()
            file.title = fileTitle
            self.chechTransfer(items: [file], to: folder) { [self] status, items, message in
                switch status {
                case .end:
                    if let items = items as? [ASCEntity] {
                        guard items.isEmpty else {
                            log.error(status, items, message ?? "")
                            completeon?(self, nil, false, nil)
                            return
                        }
                    }

                    if let templatePath = ASCFileManager.documentTemplatePath(with: fileExtension) {
                        let localUrl = Path(templatePath).url

                        let remotePath = folder.id.contains("id:") ? "\(folder.id):/\(fileTitle):/" : (Path(folder.id) + fileTitle).rawValue

                        operationProcess = provider.copyItem(localFile: localUrl, to: remotePath) { [weak self] error in
                            if error != nil {
                                guard let self = self else { return }
                                log.error(error!.localizedDescription)
                                completeon?(self, nil, false, ASCProviderError(error!))
                            }
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                if let error = error {
                                    log.error(error.localizedDescription)
                                    completeon?(self, nil, false, ASCProviderError(error))
                                } else {
                                    provider.attributesOfItem(path: remotePath, completionHandler: { [weak self] fileObject, error in
                                        DispatchQueue.main.async { [weak self] in
                                            guard let self = self else { return }

                                            if let error = error {
                                                log.debug(error)
                                                completeon?(self, nil, false, ASCProviderError(error))
                                            } else if let fileObject = fileObject {
                                                let cloudFile = self.makeCloudFile(from: fileObject)

                                                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                                                    ASCAnalytics.Event.Key.portal: self.provider?.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                                                    ASCAnalytics.Event.Key.onDevice: false,
                                                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                                                    ASCAnalytics.Event.Key.fileExt: cloudFile.title.fileExtension().lowercased(),
                                                ])

                                                completeon?(self, cloudFile, true, nil)
                                            } else {
                                                log.debug("couldn't get a file")
                                                completeon?(self, nil, false, nil)
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    }
                case .error:
                    completeon?(self, nil, false, ASCProviderError(msg: message ?? ""))
                default:
                    log.info(status, items ?? "", message ?? "")
                }
            }
        }
    }

    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        let path = folder.id.contains("id:") ? "\(folder.id):/\(name):/" : (Path(folder.id) + name).rawValue

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

        let folderCreateWithNameCompletion: (String) -> Void = { name in
            provider.create(folder: name, at: folder.id) { [weak self] error in

                guard let self = self else { return }

                guard error == nil else {
                    completeon?(self, nil, false, error)
                    return
                }

                self.getEntityId(by: name, in: folder) { result in
                    switch result {
                    case let .success(id):
                        let nowDate = Date()
                        let cloudFolder = ASCFolder()
                        cloudFolder.id = "id:\(id)"
                        cloudFolder.rootFolderType = .onedriveAll
                        cloudFolder.title = name
                        cloudFolder.created = nowDate
                        cloudFolder.updated = nowDate
                        cloudFolder.createdBy = self.user
                        cloudFolder.updatedBy = self.user
                        cloudFolder.parent = folder
                        cloudFolder.parentId = folder.id

                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                            ASCAnalytics.Event.Key.portal: provider.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                            ASCAnalytics.Event.Key.onDevice: false,
                            ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.folder,
                        ])

                        DispatchQueue.main.async {
                            completeon?(self, cloudFolder, true, nil)
                        }
                    case let .failure(error):
                        DispatchQueue.main.async {
                            completeon?(self, nil, false, error)
                        }
                    }
                }
            }
        }

        findUniqName(suggestedName: name, inFolder: folder, completionHandler: folderCreateWithNameCompletion)
    }

    private func getEntityId(by name: String, in folder: ASCFolder, completion: @escaping (Result<String, Error>) -> Void) {
        getEntityInfo(by: name, in: folder) { result in
            switch result {
            case let .success(oneDriveFileObject):
                guard let id = oneDriveFileObject.id else {
                    completion(.failure(NetworkingError.unknown(error: nil)))
                    return
                }

                completion(.success(id))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func getEntityInfo(by name: String, in folder: ASCFolder, completion: @escaping (Result<OneDriveFileObject, Error>) -> Void) {
        guard let provider = provider else {
            completion(.failure(NetworkingError.unknown(error: nil)))
            return
        }

        let foundPathCompletion: (String?, Error?) -> Void = { folderPath, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }

            guard let folderPath = folderPath else {
                completion(.failure(NetworkingError.unknown(error: nil)))
                return
            }

            let path = folderPath.appendingPathComponent(name)

            provider.attributesOfItem(path: path) { entity, error in
                guard error == nil else {
                    completion(.failure(error!))
                    return
                }

                guard let entity = entity, let oneDriveFileObject = entity as? OneDriveFileObject else {
                    completion(.failure(NetworkingError.unknown(error: nil)))
                    return
                }
                completion(.success(oneDriveFileObject))
            }
        }

        if folder.id.isEmpty {
            foundPathCompletion("/", nil)
        } else {
            provider.pathOfItem(withId: folder.id, completionHandler: foundPathCompletion)
        }
    }

    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler?) {
        guard let provider = provider else {
            handler?(.error, nil, ASCProviderError(msg: errorProviderUndefined).localizedDescription)
            return
        }

        var conflictItems: [Any] = []

        handler?(.begin, nil, nil)

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        let pathFoundCompletion: (String?, Error?) -> Void = { path, error in
            for entity in items {
                operationQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    let file = entity as? ASCFile
                    let fileName = file?.title ?? entity.id
                    let completionHandler: (FileObject?, Error?) -> Void = { object, error in
                        if error == nil, object != nil {
                            conflictItems.append(entity)
                        }
                        semaphore.signal()
                    }

                    if let folderPath = path, error == nil {
                        log.info("Getting attributes by path \(folderPath.appendingPathComponent(fileName))")
                        provider.attributesOfItem(path: folderPath.appendingPathComponent(fileName), completionHandler: completionHandler)
                    } else {
                        log.error(error ?? "Path wasn't taken")
                        log.info("Getting attributes by folder id and file name")
                        provider.attributesOfItem(folderId: folder.id, fileName: fileName, completionHandler: completionHandler)
                    }
                    semaphore.wait()
                }
            }

            operationQueue.addOperation {
                DispatchQueue.main.async {
                    handler?(.end, conflictItems, nil)
                }
            }
        }

        if folder.id.isEmpty {
            pathFoundCompletion("/", nil)
        } else {
            provider.pathOfItem(withId: folder.id, completionHandler: pathFoundCompletion)
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
        let destPath = folder.id.isEmpty ? "/drive/root:" : folder.id
        for (index, entity) in items.enumerated() {
            operationQueue.addOperation {
                if cancel {
                    DispatchQueue.main.async {
                        handler?(.end, 1, results, lastError?.localizedDescription, &cancel)
                    }
                    return
                }

                let semaphore = DispatchSemaphore(value: 0)

                if move {
                    _ = provider.moveItem(path: entity.id, to: destPath, overwrite: overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async {
                            handler?(.progress, Float(index) / Float(items.count), entity, error?.localizedDescription, &cancel)
                        }
                        semaphore.signal()
                    })
                } else {
                    _ = provider.copyItem(path: entity.id, to: destPath, overwrite: overwrite, completionHandler: { error in
                        if let error = error {
                            lastError = error
                        } else {
                            results.append(entity)
                        }
                        DispatchQueue.main.async {
                            handler?(.progress, Float(index + 1) / Float(items.count), entity, error?.localizedDescription, &cancel)
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
                    handler?(.end, 1, results, lastError?.localizedDescription, &cancel)
                }
            }
        }
    }

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

    func open(file: ASCFile, openViewMode: Bool, canEdit: Bool) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let allowOpen = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if allowOpen {
            let editMode = !openViewMode && UIDevice.allowEditor
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
            let closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))

            ASCEditorManager.shared.editFileLocally(
                for: self,
                file,
                openViewMode: !editMode,
                canEdit: canEdit && UIDevice.allowEditor,
                handler: openHandler,
                closeHandler: closeHandler
            )
        }
    }

    func preview(file: ASCFile, files: [ASCFile]? = nil, in view: UIView? = nil) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isPdf = fileExt == "pdf"
        let isImage = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo = ASCConstants.FileExtensions.videos.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            ASCEditorManager.shared.browsePdfCloud(for: self, file, handler: openHandler)
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

// MARK: - FileProviderDelegate

class ASCOneDriveProviderDelegate: FileProviderDelegate {
    // MARK: - FileProviderDelegate variables

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
