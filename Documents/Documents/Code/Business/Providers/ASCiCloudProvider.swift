//
//  ASCiCloudProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 28.07.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import CloudKit
import FileKit
import FilesProvider
import Firebase
import UIKit

class ASCiCloudProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {
    // MARK: - Properties

    var type: ASCFileProviderType {
        return .icloud
    }

    var id: String? {
        guard let identifier = identifier else { return nil }
        return identifier.md5
    }

    var rootFolder: ASCFolder {
        return {
            $0.title = NSLocalizedString("iCloud Drive", comment: "")
            $0.rootFolderType = .icloudAll
            $0.id = ""
            return $0
        }(ASCFolder())
    }

    var authorization: String? {
        return nil
    }

    private(set) var hasiCloudAccount = false

    var user: ASCUser?
    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0
    var delegate: ASCProviderDelegate?
    var filterController: ASCFiltersControllerProtocol?

    var folder: ASCFolder?
    var fetchInfo: [String: Any?]?
    var provider: CloudFileProvider?

    fileprivate let identifier: String? = (Bundle.main.bundleIdentifier != nil) ? ("iCloud." + Bundle.main.bundleIdentifier!) : nil
    fileprivate lazy var providerOperationDelegate = ASCiCloudProviderDelegate()
    private let watcherQuery = NSMetadataQuery()
    private var watcherObserver: Any?
    private var operationProcess: Progress?
    fileprivate var operationHendlers: [(
        uid: String,
        provider: FileProviderBasic,
        progress: Progress,
        delegate: ASCiCloudProviderDelegate
    )] = []

    private let errorProviderUndefined = NSLocalizedString("Unknown file provider", comment: "")

    // MARK: - Lifecycle Methods

    func initialize(_ complation: ((Bool) -> Void)? = nil) {
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                complation?(false)
                return
            }

            strongSelf.provider = CloudFileProvider(containerId: strongSelf.identifier, scope: .documents)

            semaphore.signal()
        }

        semaphore.wait()

        DispatchQueue.main.async {
            self.userInfo { success, error in
                DispatchQueue.main.async {
                    complation?(success)
                }
            }
        }
    }

    func copy() -> ASCFileProviderProtocol {
        let copy = ASCiCloudProvider()

        copy.provider = provider
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

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue,
            "hasiCloudAccount": hasiCloudAccount,
        ]

        if let user = user {
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

            hasiCloudAccount = json["hasiCloudAccount"] as? Bool ?? false
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

    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        let container = CKContainer.default()

        container.accountStatus { [weak self] accountStatus, error in
            guard let strongSelf = self else {
                completeon?(false, nil)
                return
            }

            strongSelf.hasiCloudAccount = accountStatus == .available

            strongSelf.user = ASCUser()
            strongSelf.user?.userId = strongSelf.identifier
//            strongSelf.user?.firstName = "iCloud"
//            strongSelf.user?.lastName = ""
            strongSelf.user?.displayName = "iCloud Drive"

            DispatchQueue.main.async {
                completeon?(true, nil)
            }

//            if accountStatus == .available {
//
//                strongSelf.user = ASCUser()
//                strongSelf.user?.userId = strongSelf.identifier
//                strongSelf.user?.firstName = "iCloud"
//                strongSelf.user?.lastName = ""
//                strongSelf.user?.displayName = "iCloud"
//
//                container.requestApplicationPermission(.userDiscoverability) { [weak self] status, error in
//
//                    if status == .granted {
//                        container.fetchUserRecordID { [weak self] recordId, error in
//                            guard let recordId = recordId else {
//                                completeon?(false, nil)
//                                return
//                            }
//
//                            container.discoverUserIdentity(withUserRecordID: recordId) { [weak self] userId, error in
//                                guard let userId = userId else {
//                                    completeon?(false, nil)
//                                    return
//                                }
//
//                                self?.user?.userId = userId.lookupInfo?.emailAddress ?? userId.lookupInfo?.phoneNumber
//                                self?.user?.firstName = userId.nameComponents?.givenName
//                                self?.user?.lastName = userId.nameComponents?.familyName
//                                self?.user?.displayName = (self?.user?.firstName ?? "") + " " + (self?.user?.lastName ?? "")
//
//                                DispatchQueue.main.async {
//                                    completeon?(true, nil)
//                                }
//                            }
//                        }
//                    }
//                }
//            } else {
//                DispatchQueue.main.async {
//                    completeon?(false, nil)
//                }
//            }
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

    private func directLink(from publicLink: String) -> String? {
        let getQueryStringParameter: ((String, String) -> String?) = { url, param -> String? in
            guard let url = URLComponents(string: url) else { return nil }
            return url.queryItems?.first(where: { $0.name == param })?.value
        }

        let expandParams: (String?) -> String? = { value -> String? in
            guard let value = value else { return nil }
            var expandValue = value

            if let regex = try? NSRegularExpression(pattern: "\\$\\{(\\w+)\\}", options: []) {
                let matches = regex.matches(in: value,
                                            options: [],
                                            range: NSRange(location: 0, length: value.count))
                for match in matches {
                    let stringKey = String(value[Range(match.range, in: value)!])
                    let queryKey = stringKey.trimmingCharacters(in: CharacterSet.letters.inverted)

                    if let value = getQueryStringParameter(publicLink, queryKey) {
                        expandValue = expandValue.replacingOccurrences(of: stringKey, with: value)
                    }
                }
            }
            return expandValue
        }

        return expandParams(getQueryStringParameter(publicLink, "u"))
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
                query = NSPredicate(format: "(name BEGINSWITH[c] %@)", text.lowercased())
            }

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
                            cloudFolder.providerType = .iCloud
                            cloudFolder.rootFolderType = .icloudAll
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
                            cloudFile.rootFolderType = .icloudAll
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
                            getLinkQueue.addOperation { [weak self] in
                                let semaphore = DispatchSemaphore(value: 0)

                                provider.publicLink(to: file.id) { [weak self] link, fileObj, expiration, error in
                                    if let viewUrl = link?.absoluteString {
                                        // Transfor public link to direct link
                                        let directLink = self?.directLink(from: viewUrl) ?? viewUrl
                                        print(directLink)
                                        files.first(where: { $0.id == file.id })?.viewUrl = directLink
                                    }
                                    semaphore.signal()
                                }
                                semaphore.wait()
                            }
                        }

                        getLinkQueue.waitUntilAllOperationsAreFinished()
                    }

                    // Sort
                    strongSelf.fetchInfo = parameters

                    if let sortInfo = parameters["sort"] as? [String: Any] {
                        self?.sort(by: sortInfo, folders: &folders, files: &files)
                    }

                    strongSelf.items = folders as [ASCEntity] + files as [ASCEntity]
                    strongSelf.total = strongSelf.items.count

                    strongSelf.registerNotifcation(path: folder.id)

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
        guard
            let path = string,
            let provider = provider
        else { return nil }

        // Public link
        if path.hasPrefix("http"), let validUrl = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: validUrl)
        }

        // Local path
        return provider.url(of: path)
    }

    func relativePathOf(url: URL) -> String? {
        return provider?.relativePathOf(url: url)
    }

    func download(_ path: String, to destinationURL: URL, range: Range<Int64>? = nil, processing: @escaping NetworkProgressHandler) {
        guard let provider else {
            processing(nil, 0, nil)
            return
        }

        var downloadProgress: Progress?

        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                processing(nil, 0, nil)
                return
            }

            if let localProvider = provider.copy() as? CloudFileProvider {
                let handlerUid = UUID().uuidString
                let operationDelegate = ASCiCloudProviderDelegate()
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
                    strongSelf.operationHendlers.append((
                        uid: handlerUid,
                        provider: localProvider,
                        progress: localProgress,
                        delegate: operationDelegate
                    ))
                }
            } else {
                DispatchQueue.main.async {
                    processing(nil, 0, nil)
                }
            }
        }
    }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        guard let provider = provider else {
            processing(nil, 0, nil)
            return
        }

        providerOperationDelegate.onSucceed = { [weak self] fileProvider, operation in
            self?.operationProcess = nil

            self?.attributesOfItem(path: path, completionHandler: { fileObject, error in
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
                        cloudFile.rootFolderType = .icloudAll
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

        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                DispatchQueue.main.async {
                    processing(nil, 0, nil)
                }
                return
            }

            if let localProvider = provider.copy() as? CloudFileProvider {
                let handlerUid = UUID().uuidString
                let operationDelegate = ASCiCloudProviderDelegate()

                let cleanupHendler: (String) -> Void = { [weak self] uid in
                    if let processIndex = self?.operationHendlers.firstIndex(where: { $0.uid == uid }) {
                        self?.operationHendlers.remove(at: processIndex)
                    }
                }

                operationDelegate.onSucceed = { fileProvider, operation in
                    self?.attributesOfItem(path: dstPath, completionHandler: { fileObject, error in
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
                                cloudFile.rootFolderType = .icloudAll
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
                    strongSelf.operationHendlers.append((
                        uid: handlerUid,
                        provider: localProvider,
                        progress: localProgress,
                        delegate: operationDelegate
                    ))
                }
            } else {
                DispatchQueue.main.async {
                    processing(nil, 0, nil)
                }
            }
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let provider = provider else {
            completeon?(self, nil, false, ASCProviderError(msg: errorProviderUndefined))
            return
        }

        let fileTitle = resolve(fileTitle: name + "." + fileExtension, for: items.filter { $0 is ASCFile } as? [ASCFile] ?? [])
            ?? name + "." + fileExtension

        guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path(folder.id) + fileTitle) else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create file with this name.", comment: "")))
            return
        }

        // Copy empty template to desination path
        if let templatePath = ASCFileManager.documentTemplatePath(with: fileExtension) {
            let localUrl = Path(templatePath).url
            let remotePath = filePath.rawValue

            operationProcess = provider.copyItem(localFile: localUrl, to: remotePath) { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        log.error(error.localizedDescription)
                        completeon?(strongSelf, nil, false, ASCProviderError(msg: error.localizedDescription))
                    } else {
                        self?.attributesOfItem(path: remotePath, completionHandler: { [weak self] fileObject, error in
                            DispatchQueue.main.async { [weak self] in
                                guard let strongSelf = self else { return }

                                if let error = error {
                                    completeon?(strongSelf, nil, false, ASCProviderError(msg: error.localizedDescription))
                                }
                                let fileSize: UInt64 = (filePath.fileSize ?? 0 < 0) ? 0 : UInt64(filePath.fileSize ?? 0)
                                let cloudFile = ASCFile()
                                cloudFile.id = filePath.rawValue
                                cloudFile.rootFolderType = .icloudAll
                                cloudFile.title = filePath.fileName
                                cloudFile.created = filePath.creationDate ?? filePath.modificationDate
                                cloudFile.updated = filePath.modificationDate
                                cloudFile.createdBy = strongSelf.user
                                cloudFile.updatedBy = strongSelf.user
                                cloudFile.parent = folder
                                cloudFile.viewUrl = filePath.rawValue
                                cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                                cloudFile.pureContentLength = Int(fileSize)

                                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                                    ASCAnalytics.Event.Key.portal: "icloud",
                                    ASCAnalytics.Event.Key.onDevice: false,
                                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                                    ASCAnalytics.Event.Key.fileExt: cloudFile.title.fileExtension().lowercased(),
                                ])

                                completeon?(strongSelf, cloudFile, true, nil)
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
        let fileTitle = resolve(fileTitle: name, for: items.filter { $0 is ASCFile } as? [ASCFile] ?? []) ?? name
        let path = (Path(folder.id) + fileTitle).rawValue

        upload(path, data: data, overwrite: false, params: nil) { result, progress, error in
            if let _ = result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: "icloud",
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

        let folderTitle = resolve(folderTitle: name, for: items.filter { $0 is ASCFolder } as? [ASCFolder] ?? [])
            ?? name

        provider.create(folder: folderTitle, at: folder.id) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                if let error = error {
                    completeon?(strongSelf, nil, false, error)
                } else {
                    let path = (Path(folder.id) + name).rawValue + "/"
                    let nowDate = Date()

                    let cloudFolder = ASCFolder()
                    cloudFolder.id = path
                    cloudFolder.rootFolderType = .icloudAll
                    cloudFolder.title = name
                    cloudFolder.created = nowDate
                    cloudFolder.updated = nowDate
                    cloudFolder.createdBy = strongSelf.user
                    cloudFolder.updatedBy = strongSelf.user
                    cloudFolder.parent = folder
                    cloudFolder.parentId = folder.id

                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                        ASCAnalytics.Event.Key.portal: "icloud",
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
//        guard let provider = provider else {
//            handler?(.error, nil, ASCProviderError(msg: errorProviderUndefined).localizedDescription)
//            return
//        }

        var conflictItems: [Any] = []

        handler?(.begin, nil, nil)

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        for entity in items {
            operationQueue.addOperation { [weak self] in
                let semaphore = DispatchSemaphore(value: 0)
                let destPath = NSString(string: folder.id).appendingPathComponent(NSString(string: entity.id).lastPathComponent)
                let entityName = entity is ASCFile ? entity.id.fileName() + "." + entity.id.fileExtension() : entity.id.fileName()

                self?.attributesOfItem(path: destPath, completionHandler: { object, error in
                    if object?.name == entityName {
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

                func moveItemHandler(error: Error!) {
                    if let error = error {
                        lastError = error
                        semaphore.signal()
                    } else {
                        results.append(entity)
                        DispatchQueue.main.async {
                            handler?(.progress, Float(index) / Float(items.count), entity, error, &cancel)
                        }
                        semaphore.signal()
                    }
                }

                if conflictResolveType == .overwrite {
                    provider.contents(path: destPath) { data, error in
                        if data != nil {
                            provider.removeItem(path: destPath) { removeError in
                                if let removeError = removeError {
                                    lastError = removeError
                                    semaphore.signal()
                                    return
                                } else {
                                    provider.moveItem(path: entity.id, to: destPath, completionHandler: moveItemHandler)
                                }
                            }
                            return
                        } else {
                            provider.moveItem(path: entity.id, to: destPath, completionHandler: moveItemHandler)
                            return
                        }
                    }
                } else {
                    provider.contents(path: destPath) { data, error in
                        if data != nil {
                            self.createNewPath(title: entity.id.fileName() + "." + entity.id.fileExtension(), in: folder) { newPath in
                                provider.moveItem(path: entity.id, to: newPath, completionHandler: moveItemHandler)
                            }
                        } else {
                            provider.moveItem(path: entity.id, to: destPath, completionHandler: moveItemHandler)
                        }
                    }
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

    func createNewPath(title: String, in folder: ASCFolder, completion: @escaping (String) -> Void) {
        let query = NSPredicate(format: "TRUEPREDICATE")
        var newName = title

        provider?.searchFiles(path: folder.id, recursive: true, query: query, foundItemHandler: nil, completionHandler: { files, error in
            guard error == nil else {
                print("Error searching files: \(error!)")
                completion("unknown")
                return
            }

            let fileNames = files.map { $0.name }
            newName = self.resolve(fileTitle: title, for: fileNames) ?? title

            let newPath = NSString(string: folder.id).appendingPathComponent(newName)
            completion(newPath)
        })
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

            entityActions.insert(.select)

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

        let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
        let closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))
        let renameHandler: ASCEditorManagerRenameHandler = { file, title, complation in
            guard let file else { complation(false); return }

            self.rename(file, to: title) { provider, result, success, error in
                if let file = result as? ASCFile {
                    complation(file.title.fileName() == title)
                } else {
                    complation(false)
                }
            }
        }

        if isPdf {
            ASCEditorManager.shared.browsePdfCloud(for: self, file, openHandler: openHandler, closeHandler: closeHandler, renameHandler: renameHandler)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else {
            if let view = view {
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }

    // MARK: - Helpers

    private func resolve(fileTitle: String, for files: [ASCFile]) -> String? {
        let fileName = fileTitle.fileName()
        let fileExtension = fileTitle.fileExtension()
        let conflict: (String) -> Bool = { title in
            files.contains(where: { $0.title == title })
        }

        var resolveTitle = fileTitle

        // Add postfix if file exist
        if conflict(resolveTitle) {
            for index in 2 ... 100 {
                resolveTitle = (fileName + "-\(index)." + fileExtension)

                if !conflict(resolveTitle) {
                    return resolveTitle
                }
            }
        }

        return conflict(resolveTitle) ? nil : resolveTitle
    }

    private func resolve(folderTitle: String, for folders: [ASCFolder]) -> String? {
        let conflict: (String) -> Bool = { title in
            folders.contains(where: { $0.title == title })
        }

        var resolveTitle = folderTitle

        // Add postfix if folder exist
        if conflict(resolveTitle) {
            for index in 2 ... 100 {
                resolveTitle = folderTitle + "-\(index)"

                if !conflict(resolveTitle) {
                    return resolveTitle
                }
            }
        }

        return conflict(resolveTitle) ? nil : resolveTitle
    }

    private func resolve(fileTitle: String, for fileNames: [String]) -> String? {
        let fileName = fileTitle.fileName()
        let fileExtension = fileTitle.fileExtension()

        let conflict: (String) -> Bool = { title in
            fileNames.contains(title)
        }

        let resolveTitle = fileTitle

        if conflict(resolveTitle) {
            for index in 2 ... 100 {
                let newTitle = fileName + "-\(index)" + (fileExtension.isEmpty ? "" : ".\(fileExtension)")
                if !conflict(newTitle) {
                    return newTitle
                }
            }

            return nil
        }

        return resolveTitle
    }

    // MARK: - File watcher

    /// Starts monitoring a path and its subpaths, including files and folders, for any change,
    /// including copy, move/rename, content changes, etc.
    ///
    ///  - Parameters:
    ///   - path: path of directory.
    ///   - eventHandler: Closure executed after change, on a secondary thread.
    private func registerNotifcation(path: String) {
        guard let provider = provider else {
            return
        }

        unregisterNotifcation(path: path)
        let pathURL = provider.url(of: path)
        watcherQuery.predicate = NSPredicate(format: "(%K BEGINSWITH %@)", NSMetadataItemPathKey, pathURL.path)
        watcherQuery.valueListAttributes = []
        watcherQuery.searchScopes = [provider.scope.rawValue]

        watcherObserver = NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: watcherQuery, queue: nil, using: { [weak self] notification in
            guard let strongSelf = self else { return }
            strongSelf.watcherQuery.disableUpdates()
            strongSelf.handleWatchUpdate(notification)
            strongSelf.watcherQuery.enableUpdates()
        })

        DispatchQueue.main.async { [weak self] in
            self?.watcherQuery.start()
        }
    }

    /// Stops monitoring the path.
    ///
    /// - Parameter path: path of directory.
    private func unregisterNotifcation(path: String) {
        if watcherQuery.isStarted {
            watcherQuery.disableUpdates()
            watcherQuery.stop()
        }

        if let observer = watcherObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleWatchUpdate(_ notification: Notification) {
        guard let folder = folder else { return }

        let isOwnerEntity: ((ASCEntity) -> Bool) = { entity -> Bool in
            guard
                let parentPath = (entity as? ASCFolder)?.parent?.id ?? (entity as? ASCFile)?.parent?.id
            else { return false }

            return folder.id == parentPath
        }

        let attributes = [
            NSMetadataItemURLKey, NSMetadataItemFSNameKey, NSMetadataItemPathKey,
            NSMetadataItemFSSizeKey, NSMetadataItemContentTypeTreeKey, NSMetadataItemFSCreationDateKey,
            NSMetadataItemFSContentChangeDateKey,
        ]

        /// Filter changes only for current folder
        let addedItems = (notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] ?? [])
            .compactMap { mapEntity(attributes: $0.values(forAttributes: attributes) ?? [:]) }
            .filter { isOwnerEntity($0) }
        let changedItems = (notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] ?? [])
            .compactMap { mapEntity(attributes: $0.values(forAttributes: attributes) ?? [:]) }
            .filter { isOwnerEntity($0) }
        let removedItems = (notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem] ?? [])
            .compactMap { mapEntity(attributes: $0.values(forAttributes: attributes) ?? [:]) }
            .filter { isOwnerEntity($0) }

        /// Have any change
        if addedItems.count + changedItems.count + removedItems.count > 0 {
//            fetch(for: folder, parameters: fetchInfo ?? [:]) { [weak self] provider, folder, success, error in
//                guard let strongSelf = self else { return }
//                strongSelf.delegate?.updateItems(provider: strongSelf)
//            }

            for newItem in addedItems {
                if items.firstIndex(where: { $0.id == newItem.id }) == nil {
                    items.append(newItem)
                }
            }

            for removeItem in removedItems {
                if let removeIndex = items.firstIndex(where: { $0.id == removeItem.id }) {
                    items.remove(at: removeIndex)
                }
            }

            for updateItem in changedItems {
                if let updateIndex = items.firstIndex(where: { $0.id == updateItem.id }) {
                    items[updateIndex] = updateItem
                }
            }

            var folders: [ASCFolder] = items.filter { $0 is ASCFolder } as? [ASCFolder] ?? []
            var files: [ASCFile] = items.filter { $0 is ASCFile } as? [ASCFile] ?? []

            let defaultSortInfo = [
                "type": "dateandtime",
                "order": "descending",
            ]
            let sortInfo = fetchInfo?["sort"] as? [String: Any] ?? defaultSortInfo
            sort(by: sortInfo, folders: &folders, files: &files)

            items = folders as [ASCEntity] + files as [ASCEntity]
            total = items.count

            delegate?.updateItems(provider: self)
        }
    }

    private func mapEntity(attributes attribs: [String: Any]) -> ASCEntity? {
        guard
            let provider = provider,
            let url = (attribs[NSMetadataItemURLKey] as? URL)?.standardizedFileURL,
            let name = attribs[NSMetadataItemFSNameKey] as? String
        else { return nil }

        let path = provider.relativePathOf(url: url)
        let isFolder = (attribs[NSMetadataItemContentTypeTreeKey] as? [String])?.contains("public.folder") ?? false
        let size = (attribs[NSMetadataItemFSSizeKey] as? NSNumber)?.int64Value ?? -1
        let creationDate = attribs[NSMetadataItemFSCreationDateKey] as? Date
        let modifiedDate = attribs[NSMetadataItemFSContentChangeDateKey] as? Date

        let parent = ASCFolder()
        parent.id = path.deletingLastPathComponent.replacingOccurrences(of: provider.baseURL?.path ?? "", with: "")

        if isFolder {
            let folder = ASCFolder()
            folder.id = path.replacingOccurrences(of: provider.baseURL?.path ?? "", with: "")
            folder.providerType = .iCloud
            folder.rootFolderType = .icloudAll
            folder.title = name
            folder.created = creationDate ?? modifiedDate
            folder.updated = modifiedDate
            folder.createdBy = user
            folder.updatedBy = user
            folder.parent = parent
            folder.parentId = parent.id
            return folder
        } else {
            let fileSize: UInt64 = (size < 0) ? 0 : UInt64(size)
            let file = ASCFile()
            file.id = path.replacingOccurrences(of: provider.baseURL?.path ?? "", with: "")
            file.rootFolderType = .icloudAll
            file.title = name
            file.created = creationDate ?? modifiedDate
            file.updated = modifiedDate
            file.createdBy = user
            file.updatedBy = user
            file.parent = parent
            file.viewUrl = path
            file.displayContentLength = String.fileSizeToString(with: fileSize)
            file.pureContentLength = Int(fileSize)
            return file
        }
    }

    private func attributesOfItem(path: String, completionHandler: @escaping (_ attributes: FileObject?, _ error: Error?) -> Void) {
        guard let provider = provider else {
            completionHandler(nil, ASCProviderError(msg: errorProviderUndefined))
            return
        }

        let query = NSPredicate(format: "TRUEPREDICATE")
        provider.searchFiles(path: path, recursive: true, query: query, foundItemHandler: nil, completionHandler: { files, error in
            completionHandler(files.first, error)
        })
    }
}

// MARK: - FileProvider Delegate

class ASCiCloudProviderDelegate: FileProviderDelegate {
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
