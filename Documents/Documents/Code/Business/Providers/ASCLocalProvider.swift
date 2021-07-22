//
//  ASCLocalProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit
import Firebase

class ASCLocalProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {
    var id: String? {
        get {
            return "device"
        }
    }
    var type: ASCFileProviderType {
        get {
            return .local
        }
    }

    var items: [ASCEntity] = []
    var page: Int = 0
    var total: Int = 0
    var authorization: String?

    var user: ASCUser? {
        get {
            return deviceUser
        }
    }

    var delegate: ASCProviderDelegate?
    
    internal var folder: ASCFolder?
    internal var fetchInfo: [String : Any?]?

    fileprivate lazy var deviceUser: ASCUser = {
        let owner = ASCUser()
        owner.displayName = UIDevice.displayName
        return owner
    }()

    var rootFolder: ASCFolder = {
        $0.title = NSLocalizedString("Documents", comment: "Category title")
        $0.rootFolderType = .deviceDocuments
        $0.id = Path.userDocuments.rawValue
        $0.device = true
        return $0
    }(ASCFolder())

    func copy() -> ASCFileProviderProtocol {
        let copy = ASCLocalProvider()
        
        copy.items = items.map { $0 }
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.authorization = authorization
        
        return copy
    }

    func reset() {
        total = 0
        items.removeAll()
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
        var folders = [ASCFolder]()
        var files = [ASCFile]()
        let paths = ASCLocalFileHelper.shared.entityList(Path(folder.id))

        self.folder = folder
        
        for path in paths {
            let owner = ASCUser()
            owner.displayName = UIDevice.displayName

            if path.isDirectory {
                let localFolder = ASCFolder()

                localFolder.id = path.rawValue
                localFolder.rootFolderType = folder.rootFolderType
                localFolder.title = path.fileName
                localFolder.created = path.creationDate
                localFolder.updated = path.modificationDate
                localFolder.createdBy = owner
                localFolder.updatedBy = owner
                localFolder.filesCount = -1
                localFolder.foldersCount = -1
                localFolder.device = true
                localFolder.parent = folder
                localFolder.parentId = folder.id

                // Exclude file system folder
                if folder.parent == nil && path.fileName == "Inbox" {
                    continue
                }

                folders.append(localFolder)
            } else {
                // Exclude file system folder
                let parentFolder = path.parent
                if parentFolder.fileName == ".Trash" {
                    continue
                }

                let localFile = ASCFile()

                localFile.id = path.rawValue
                localFile.viewUrl = path.rawValue
                localFile.rootFolderType = folder.rootFolderType
                localFile.title = path.fileName
                localFile.created = path.creationDate
                localFile.updated = path.modificationDate
                localFile.createdBy = owner
                localFile.updatedBy = owner
                localFile.device = true
                localFile.parent = folder
                localFile.displayContentLength = String.fileSizeToString(with: path.fileSize ?? 0)
                localFile.pureContentLength = Int(path.fileSize ?? 0)

                files.append(localFile)
            }
        }

        // Sort
        fetchInfo = parameters
        
        if let sortInfo = parameters["sort"] as? [String: Any] {
            sort(by: sortInfo, folders: &folders, files: &files)
        }

        var commonList = folders as [ASCEntity] + files as [ASCEntity]

        // Search
        if let searchInfo = parameters["search"] as? [String: Any] {
            search(by: searchInfo, entities: &commonList)
        }

        total = commonList.count
        items = commonList

        completeon?(self, folder, true, nil)
    }

    /// Search records
    ///
    /// - Parameters:
    ///   - info: Search information as dictinory
    ///   - entities: Records found
    private func search(by info: [String: Any], entities: inout [ASCEntity]) {
        if let searchText = (info["text"] as? String)?.lowercased(), searchText.length > 0 {
            entities = entities.filter() { entity in
                if let file = entity as? ASCFile {
                    return file.title.lowercased().range(of: searchText) != nil
                } else if let folder = entity as? ASCFolder {
                    return folder.title.lowercased().range(of: searchText) != nil
                }
                return false
            }
        }
    }

    /// Sort records
    ///
    /// - Parameters:
    ///   - completeon: a closure with result of sort entries or error
    func updateSort(completeon: ASCProviderCompletionHandler?) {
        if let sortInfo = fetchInfo?["sort"] as? [String : Any] {
            sort(by: sortInfo, entities: &items)
            total = items.count
        }
        completeon?(self, folder, true, nil)
    }
    
    func download(_ path: String, to destinationURL: URL, processing: @escaping ASCApiProgressHandler) {
        processing(0, nil, nil, nil)

        if let error = ASCLocalFileHelper.shared.copy(from: Path(path), to: Path(destinationURL.path)) {
            processing(1, nil, error, nil)
        } else {
            processing(1, Path(path), nil, nil)
        }
    }

    func upload(_ path: String, data: Data, overwrite: Bool, params: [String : Any]?, processing: @escaping ASCApiProgressHandler) {
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

        if let error = ASCLocalFileHelper.shared.copy(from: dummyFilePath, to: Path(dstPath)) {
            processing(1, nil, error, nil)
        } else {
            let destFilePath = Path(dstPath)
            let owner = ASCUser()
            owner.displayName = UIDevice.displayName

            let parenFolder = ASCFolder()
            parenFolder.id = destFilePath.parent.rawValue
            parenFolder.title = destFilePath.parent.fileName
            parenFolder.device = true


            let localFile = ASCFile()
            localFile.id = destFilePath.rawValue
            localFile.rootFolderType = .deviceDocuments
            localFile.title = destFilePath.fileName
            localFile.created = destFilePath.creationDate
            localFile.updated = destFilePath.creationDate
            localFile.createdBy = owner
            localFile.updatedBy = owner
            localFile.parent = parenFolder
            localFile.viewUrl = destFilePath.rawValue
            localFile.displayContentLength = String.fileSizeToString(with: destFilePath.fileSize ?? 0)
            localFile.pureContentLength = Int(destFilePath.fileSize ?? 0)
            localFile.device = true

            processing(1, localFile, nil, nil)
        }

        ASCLocalFileHelper.shared.removeFile(dummyFilePath)
    }

    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil && folder == nil {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }

        var oldPath: Path = Path()
        var newPath: Path = Path()

        let entityTitle = file?.title ?? folder?.title

        if let deviceFile = file {
            let fileExtension = entityTitle?.fileExtension() ?? ""

            oldPath = Path(deviceFile.id)
            newPath = oldPath.parent + (newName + (fileExtension.length < 1 ? "" : ("." + fileExtension)))
        } else if let deviceFolder = folder {
            oldPath = Path(deviceFolder.id)
            newPath = oldPath.parent + newName
        }

        if newPath.exists {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed. An object with such a similar name exists.", comment: "")))
            return
        }

        if let _ = ASCLocalFileHelper.shared.move(from: oldPath, to: newPath) {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed.", comment: "")))
            return
        } else {
            if let deviceFile = file {
                deviceFile.id = newPath.rawValue
                deviceFile.title = newPath.fileName
                deviceFile.created = newPath.creationDate
                deviceFile.updated = newPath.modificationDate

                completeon?(self, deviceFile, true, nil)
            } else if let deviceFolder = folder {
                deviceFolder.id = newPath.rawValue
                deviceFolder.title = newName
                deviceFolder.created = newPath.creationDate
                deviceFolder.updated = newPath.modificationDate

                completeon?(self, deviceFolder, true, nil)
            }
        }
    }

    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?) {
        let fromFolder = folder

        for entity in entities {
            if let file = entity as? ASCFile {
                if fromFolder.rootFolderType == .deviceTrash || (move != nil) {
                    ASCLocalFileHelper.shared.removeFile(Path(file.id))
                } else {
                    guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path.userTrash + file.title) else {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Could not delete the file.", comment: "")))
                        return
                    }

                    if let _ = ASCLocalFileHelper.shared.move(from: Path(file.id), to: filePath) {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Could not delete the file.", comment: "")))
                        return
                    }
                }
            } else if let folder = entity as? ASCFolder {
                if fromFolder.rootFolderType == .deviceTrash {
                    ASCLocalFileHelper.shared.removeDirectory(Path(folder.id))
                } else {
                    guard let folderPath = ASCLocalFileHelper.shared.resolve(folderPath: Path.userTrash + folder.title) else {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Could not delete the folder.", comment: "")))
                        return
                    }

                    if let _ = ASCLocalFileHelper.shared.move(from: Path(folder.id), to: folderPath) {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Could not delete the folder.", comment: "")))
                        return
                    }
                }
            }
        }

        completeon?(self, entities, true, nil)
    }
    
    func emptyTrash(completeon: ASCProviderCompletionHandler?) {
        // Empty local trash
        let trashItems = ASCLocalFileHelper.shared.entityList(Path.userTrash)
        
        for item in trashItems {
            ASCLocalFileHelper.shared.removeFile(item)
        }
        
        completeon?(self, nil, true, nil)
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        if folder.device || folder.rootFolderType == .deviceDocuments {
            guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path(folder.id) + (name + "." + fileExtension)) else {
                completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create file with this name.", comment: "")))
                return
            }

            // Copy empty template to desination path
            if let templatePath = ASCFileManager.documentTemplatePath(with: fileExtension) {
                do {
                    let template = try Data(contentsOfPath: Path(templatePath))
                    try template.write(to: filePath)
                } catch {
                    completeon?(self, nil, false, ASCProviderError(error))
                    return
                }

                // Create entity info
                let owner = ASCUser()
                owner.displayName = UIDevice.displayName

                let file = ASCFile()
                file.id = filePath.rawValue
                file.rootFolderType = .deviceDocuments
                file.title = filePath.fileName
                file.created = filePath.creationDate
                file.updated = filePath.modificationDate
                file.createdBy = owner
                file.updatedBy = owner
                file.device = true
                file.displayContentLength = String.fileSizeToString(with: filePath.fileSize ?? 0)
                file.pureContentLength = Int(filePath.fileSize ?? 0)

                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": "none",
                    "onDevice": true,
                    "type": "file",
                    "fileExt": file.title.fileExtension().lowercased()
                    ]
                )

                completeon?(self, file, true, nil)
            } else {
                completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create file with this name.", comment: "")))
            }
        } else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create file in the folder.", comment: "")))
        }
    }

    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        if folder.device || folder.rootFolderType == .deviceDocuments {
            processing(0, nil, nil, nil)

            let filePath = Path(folder.id) + name
            do{
                try data.write(to: filePath, atomically: true)
            } catch(let error) {
                processing(1, nil, error, nil)
                return
            }

            // Create entity info
            let owner = ASCUser()
            owner.displayName = UIDevice.displayName

            let file = ASCFile()
            file.id = filePath.rawValue
            file.title = filePath.fileName
            file.created = filePath.creationDate
            file.updated = filePath.modificationDate
            file.createdBy = owner
            file.updatedBy = owner
            file.device = true
            file.displayContentLength = String.fileSizeToString(with: filePath.fileSize ?? 0)
            file.pureContentLength = Int(filePath.fileSize ?? 0)

            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                "portal": ASCOnlyOfficeApi.shared.baseUrl ?? "none",
                "onDevice": true,
                "type": "file",
                "fileExt": file.title.fileExtension()
                ]
            )

            processing(1, file, nil, nil)
        } else {
            processing(1, nil, ASCProviderError(msg: ""), nil)
        }
    }

    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {
        if folder.device || folder.rootFolderType == .deviceDocuments {
            guard let folderPath = ASCLocalFileHelper.shared.resolve(folderPath: Path(folder.id) + name) else {
                completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create folder with this name.", comment: "")))
                return
            }

            ASCLocalFileHelper.shared.createDirectory(folderPath)

            if folderPath.exists {
                // Create entity info
                let owner = ASCUser()
                owner.displayName = UIDevice.displayName

                let newFolder = ASCFolder()
                newFolder.id = folderPath.rawValue
                newFolder.parent = folder
                newFolder.parentId = folder.id
                newFolder.rootFolderType = .deviceDocuments
                newFolder.title = folderPath.fileName
                newFolder.created = folderPath.creationDate
                newFolder.updated = folderPath.modificationDate
                newFolder.createdBy = owner
                newFolder.updatedBy = owner
                newFolder.filesCount = -1
                newFolder.foldersCount = -1
                newFolder.device = true

                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": "none",
                    "onDevice": true,
                    "type": "folder"
                    ]
                )

                completeon?(self, newFolder, true, nil)
            } else {
                completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create folder with this name.", comment: "")))
            }
        } else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Can not create folder with this name.", comment: "")))
        }
    }

    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        var conflictItems: [Any] = []

        handler?(.begin, nil, nil)

        for entity in items {
            if let title = (entity as? ASCFolder)?.title ?? (entity as? ASCFile)?.title ?? nil {
                let destPath = Path(folder.id) + title

                if destPath.exists {
                    conflictItems.append(entity)
                }
            }
        }

        handler?(.end, conflictItems, nil)
    }

    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) {
        var cancel = false

        handler?(.begin, 0, nil, nil, &cancel)

        var transfers: [Any] = []

        for entity in items {
            if let title = (entity as? ASCFolder)?.title ?? (entity as? ASCFile)?.title ?? nil,
                let path = (entity as? ASCFolder)?.id ?? (entity as? ASCFile)?.id ?? nil {
                let srcPath = Path(path)
                let destPath = Path(folder.id) + title

                if destPath.exists {
                    if overwrite, srcPath != destPath {
                        ASCLocalFileHelper.shared.removeFile(destPath)
                    } else {
                        continue
                    }
                }

                if move {
                    if let error = ASCLocalFileHelper.shared.move(from: srcPath, to: destPath) {
                        handler?(.error, 1, transfers, ASCProviderError(error).localizedDescription, &cancel)
                    } else {
                        transfers.append(entity)
                    }
                } else {
                    if let error = ASCLocalFileHelper.shared.copy(from: srcPath, to: destPath) {
                        handler?(.error, 1, transfers, ASCProviderError(error).localizedDescription, &cancel)
                    } else {
                        transfers.append(entity)
                    }
                }
            }
        }
        handler?(.end, 1, transfers, nil, &cancel)
    }

    // MARK: - Access

    func allowRead(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil && folder == nil {
            return false
        }

        return (file?.device ?? folder?.device)!
    }

    func allowEdit(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil && folder == nil {
            return false
        }

        let isDevice = (file?.device ?? folder?.device)!
        let isInTrash = (folder?.rootFolderType == .deviceTrash) || (file?.rootFolderType == .deviceTrash)

        return isDevice && !isInTrash
    }

    func allowDelete(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil && folder == nil {
            return false
        }

        return (file?.device ?? folder?.device)!
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
            let isTrash         = file.rootFolderType == .deviceTrash
            let canOpenEditor   = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                ASCConstants.FileExtensions.spreadsheets.contains(fileExtension) ||
                ASCConstants.FileExtensions.presentations.contains(fileExtension)
            let canPreview      = canOpenEditor ||
                ASCConstants.FileExtensions.images.contains(fileExtension) ||
                fileExtension == "pdf"

            if isTrash {
                return [.delete, .restore]
            }

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

            if (ASCFileManager.onlyofficeProvider?.api.active ?? false) && !isTrash {
                entityActions.insert(.upload)
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

            if folder.rootFolderType == .deviceTrash {
                return [.delete, .restore]
            }

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
    
    // MARK: - Helpers
    
    func absoluteUrl(from string: String?) -> URL? {
        return URL(fileURLWithPath: string ?? "")
    }

    // MARK: - Open file
    
    func open(file: ASCFile, viewMode: Bool = false) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let allowOpen       = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if allowOpen {
            let editMode = !viewMode && UIDevice.allowEditor
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0.15)
            let closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))

            ASCEditorManager.shared.editLocal(file, viewMode: !editMode, openHandler: openHandler, closeHandler: closeHandler)
        }
    }

    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let isPdf           = fileExt == "pdf"
        let isImage         = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo         = ASCConstants.FileExtensions.videos.contains(fileExt)

        if isPdf {
            ASCEditorManager.shared.browsePdfLocal(file)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else {
            if let view = view {
                ASCEditorManager.shared.browseUnknownLocal(file, inView: view)
            }
        }
    }
}
