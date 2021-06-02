//
//  ASCOnlyofficeProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import FileKit
import Firebase

class ASCOnlyofficeProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {
    var id: String? {
        get {
            if
                let baseUrl = api.baseUrl,
                let token = api.token
            {
                return (baseUrl + token).md5
            }
            return nil
        }
    }

    var type: ASCFileProviderType {
        get {
            return .onlyoffice
        }
    }

    var rootFolder: ASCFolder {
        get {
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeUser)
                $0.rootFolderType = .onlyofficeUser
                $0.id = ASCOnlyOfficeApi.apiFolderMy
                return $0
            }(ASCFolder())
        }
    }

    var items: [ASCEntity] = []

    var page: Int = 0
    var pageSize: Int = 20
    var total: Int = 0
    var user: ASCUser? = nil
    var authorization: String? {
        get {
            return api.isHttp2 ? "Bearer \(api.token ?? "")" : api.token
        }
    }

    var api: ASCOnlyOfficeApi {
        get {
            return ASCOnlyOfficeApi.shared
        }
    }

    var delegate: ASCProviderDelegate?
    
    internal var folder: ASCFolder?
    internal var fetchInfo: [String : Any?]?
    
    init() {
        reset()
        api.baseUrl = nil
        api.token = nil
        api.serverVersion = nil
        api.capabilities = nil
    }

    init(baseUrl: String, token: String) {
        api.baseUrl = baseUrl
        api.token = token
    }

    func copy() -> ASCFileProviderProtocol {
        let copy = ASCOnlyofficeProvider(baseUrl: api.baseUrl ?? "", token: api.token ?? "")
        
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
        ASCOnlyOfficeApi.cancelAllTasks()
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue
        ]

        if let baseUrl = api.baseUrl {
            info += ["baseUrl": baseUrl]
        }

        if let token = api.token {
            info += ["token": token]
        }

        if let serverVersion = api.serverVersion {
            info += ["serverVersion": serverVersion]
        }

        if let expires = api.expires {
            let dateTransform = ASCDateTransform()
            info += ["expires": dateTransform.transformToJSON(expires) ?? ""]
        }

        if let capabilities = api.capabilities {
            info += ["capabilities": capabilities.toJSON()]
        }

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

            if let capabilitiesJson = json["capabilities"] as? [String: Any] {
                api.capabilities = ASCPortalCapabilities(JSON: capabilitiesJson)
            }

            let dateTransform = ASCDateTransform()

            api.baseUrl = json["baseUrl"] as? String
            api.token = json["token"] as? String
            api.serverVersion = json["serverVersion"] as? String
            api.expires = dateTransform.transformFromJSON(json["expires"])
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

    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiPeopleSelf, parameters: nil) { [weak self] results, error, response in
            if let results = results as? [String: Any], error == nil {
                guard let strongSelf = self else { return }

                let postUpdate = {
                    NotificationCenter.default.post(name: ASCConstants.Notifications.userInfoOnlyofficeUpdate, object: nil)
                    ASCFileManager.storeProviders()
                }
                
                if let user = ASCUser(JSON: results) {
                    strongSelf.user = user
                    
                    if let userId = user.userId {
                        ASCOnlyOfficeApi.get(String(format: ASCOnlyOfficeApi.apiPeoplePhoto, userId)) { [weak self] results, error, response in
                            defer {
                                postUpdate()
                                completeon?(true, nil)
                            }
                            
                            guard let strongSelf = self else { return }
                            
                            if let results = results as? [String: Any], error == nil {
                                strongSelf.user?.avatarRetina = results["retina"] as? String
                            }
                        }
                    } else {
                        postUpdate()
                        completeon?(true, nil)
                    }
                } else {
                    completeon?(false, nil)
                }
            } else {
                if let response = response {
                    completeon?(false, error ?? ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response)))
                } else {
                    completeon?(false, error)
                }
            }
        }
    }

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        completionHandler(ASCNetworkReachability.shared.isReachable && api.active, nil)
    }

    /// Allow the redirection with a modified request
    ///
    /// - Parameter request: the original request
    /// - Returns: the modified request
    func modifyImageDownloader(request: URLRequest) -> URLRequest {
        var modifyRequest = request

        // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
        if let baseUrl = api.baseUrl, URL(string: baseUrl)?.host == request.url?.host {
            modifyRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        return modifyRequest
    }

    /// Fetch an Array of 'ASCEntity's identifying the the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?) {
        self.folder = folder
        
        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in
            guard let strongSelf = self else { return }

            var params: [String: Any] = [
                "page"         : (parameters["page"] as? Int) ?? strongSelf.page + 1,
                "startIndex"   : (parameters["startIndex"] as? Int) ?? strongSelf.page * strongSelf.pageSize,
                "count"        : (parameters["count"] as? Int) ?? strongSelf.pageSize
            ]

            /// Search
            if let search = parameters["search"] as? [String: Any] {
                params["filterBy"] = "title"
                params["filterOp"] = "contains"
                params["filterValue"] = (search["text"] as? String ?? "").trimmed
            }

            /// Sort
            
            strongSelf.fetchInfo = parameters
            
            if let sort = parameters["sort"] as? [String: Any] {
                if let sortBy = sort["type"] as? String, sortBy.length > 0 {
                    params["sortBy"] = sortBy
                }

                if let sortOrder = sort["order"] as? String, sortOrder.length > 0 {
                    params["sortOrder"] = sortOrder
                }
            }
            
            /// Filter
            if let filter = parameters["filterType"] as? Int {
                params["filterType"] = filter
            }

            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiFilesPath + folder.id, parameters: params) { [weak self] (results, error, response) in
                guard let strongSelf = self else { return }

                var currentFolder = folder

                if let results = results as? [String: Any] {
                    strongSelf.total = results["total"] as! Int

                    if let current = results["current"] as? [String: Any] {
                        currentFolder = ASCFolder(JSON: current) ?? folder
                    }

                    let readEntities: ((_ key: String) -> [ASCEntity]) = { key in
                        var entities: [ASCEntity] = []
                        let isFolder = key == "folders"

                        if let responseEntities = results[key] as? [[String: Any]] {
                            for entity in responseEntities {
                                if isFolder {
                                    if let folder = ASCFolder(JSON: entity) {
                                        folder.parent = currentFolder
                                        entities.append(folder)
                                    }
                                } else {
                                    if let file = ASCFile(JSON: entity) {
                                        file.parent = currentFolder
                                        entities.append(file)
                                    }
                                }
                            }
                        }

                        return entities
                    }

                    if strongSelf.page == 0 {
                        strongSelf.items.removeAll()
                    }

                    var entities: [ASCEntity] = []

                    // Load folder
                    entities += readEntities("folders")

                    // Load files
                    entities += readEntities("files")

                    strongSelf.items += entities

                    completeon?(strongSelf, currentFolder, true, nil)
                } else {
                    completeon?(strongSelf, currentFolder, false, error)
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

    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder

        if file == nil && folder == nil {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }

        let fileExtension = file?.title.fileExtension() ?? ""
        let requestPath = String(format: (file != nil ? ASCOnlyOfficeApi.apiFileId : ASCOnlyOfficeApi.apiFolderId), (file != nil ? file?.id : folder?.id) ?? "")
        let newTitle = file != nil ? (fileExtension.length < 1 ? newName : String(format:"%@.%@", newName, fileExtension)) : newName

        ASCOnlyOfficeApi.put(requestPath, parameters: ["title": newTitle], completion: { (result, error, response) in
            if error != nil {
                completeon?(self, nil, false, ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!)))
            } else {
                if let result = result as? [String: Any] {
                    if file != nil, let file = ASCFile(JSON: result) {
                        completeon?(self, file, true, nil)
                    } else if folder != nil, let folder = ASCFolder(JSON: result) {
                        completeon?(self, folder, true, nil)
                    } else {
                        completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed.", comment: "")))
                    }
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed.", comment: "")))
                }
            }
        })
    }
    
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {
        guard let file = entity as? ASCFile else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }
        
        if favorite {
            ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiFilesFavorite, parameters: ["fileIds" : [file.id]]) { result, error, response in
                if result as? Bool ?? false {
                    file.isFavorite = true
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Set favorite failed.", comment: "")))
                }
            }
        } else {
            ASCOnlyOfficeApi.delete(ASCOnlyOfficeApi.apiFilesFavorite, parameters: ["fileIds" : [file.id]]) { result, error, response in
                if result as? Bool ?? false {
                    file.isFavorite = false
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Set favorite failed.", comment: "")))
                }
            }
        }
    }

    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?) {
        let isShareRoot = folder.rootFolderType == .onlyofficeShare && (folder.parentId == nil || folder.parentId == "0")
        var folderIds: [String] = []
        var cloudFolderIds: [String] = []
        var fileIds: [String] = []
        let currentFolder = folder

        var parameters: [String: Any] = [:]

        for entity in entities {
            if let file = entity as? ASCFile {
                fileIds.append(file.id)
            } else if let folder = entity as? ASCFolder {
                if folder.isThirdParty, !currentFolder.isThirdParty {
                    cloudFolderIds.append(folder.id)
                } else {
                    folderIds.append(folder.id)
                }
            }
        }

        if folderIds.count > 0 {
            parameters["folderIds"] = folderIds
        }

        if fileIds.count > 0 {
            parameters["fileIds"] = fileIds
        }

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        var resultItems: [ASCEntity] = []
        var lastError: ASCProviderError?

        // Folder delete
        if folderIds.count + fileIds.count > 0 {
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)

                if isShareRoot {
                    ASCOnlyOfficeApi.delete(ASCOnlyOfficeApi.apiBatchShare, parameters: parameters, completion: { (results, error, response) in
                        defer { semaphore.signal() }

                        if error != nil {
                            lastError = ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!))
                        } else {
                            resultItems += entities.filter { folderIds.contains($0.id) }
                            resultItems += entities.filter { fileIds.contains($0.id) }
                        }
                    })
                } else {
                    ASCOnlyOfficeApi.put(ASCOnlyOfficeApi.apiBatchDelete, parameters: parameters, completion: { (results, error, response) in
                        defer { semaphore.signal() }

                        if error != nil {
                            lastError = ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!))
                        } else {
                            resultItems += entities.filter { folderIds.contains($0.id) }
                            resultItems += entities.filter { fileIds.contains($0.id) }
                        }
                    })
                }
                semaphore.wait()
            }
        }

        // Third party
        for cloudFolderId in cloudFolderIds {
            if  let providerFolder = entities.first(where: { $0.id == cloudFolderId }) as? ASCFolder,
                let providerId = providerFolder.providerId
            {
                operationQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    let thirdPartyPath = NSString(string: ASCOnlyOfficeApi.apiThirdParty).appendingPathComponent(providerId)

                    ASCOnlyOfficeApi.delete(thirdPartyPath, completion: { result, error, response in
                        defer { semaphore.signal() }

                        if let _ = error {
                            lastError = ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!))
                        } else if let result = result as? String {
                            let folder = ASCFolder()
                            folder.id = result
                            resultItems.append(folder)
                        }
                    })
                    semaphore.wait()
                }
            }
        }

        // Done
        operationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }

            DispatchQueue.main.async(execute: {
                completeon?(strongSelf, resultItems, resultItems.count > 0, lastError)
            })
        }
    }

    func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler) {
        api.download(path, to: to, processing: processing)
    }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        let uploadPath = String(format: ASCOnlyOfficeApi.apiSaveEditing, path)
        var uploadParams = params ?? [:]
        let mime = uploadParams["mime"] as? String

        uploadParams.removeAll(keys: ["mime"])

        api.upload(
            uploadPath,
            data: data,
            parameters: uploadParams,
            method: .put,
            mime: mime,
            processing: { (progress, result, error, response) in
                var file: ASCFile?
                if let result = result as? [String: Any] {
                    file = ASCFile(JSON: result)
                }
                processing(progress, file, error, response)
        }
        )
    }

    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        var uploadParams = params ?? [:]
        let mime = uploadParams["mime"] as? String

        uploadParams.removeAll(keys: ["mime"])

        if overwrite {
            uploadParams += [
                "createNewIfExist": "true",
            ]
        }

        api.upload(
            String(format: ASCOnlyOfficeApi.apiInsertFile, path),
            data: data,
            parameters: uploadParams,
            method: .post,
            mime: mime,
            processing: { progress, result, error, response in
                processing(progress, result, error, response)
            }
        )
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        let fileTitle = name + "." + fileExtension

        ASCOnlyOfficeApi.post(
            String(format: ASCOnlyOfficeApi.apiCreateFile, folder.id),
            parameters: ["title": fileTitle],
            completion: { result, error, response in
                if error != nil {
                    completeon?(self, nil, false, ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!)))
                } else {
                    if let result = result as? [String: Any] {
                        let file = ASCFile(JSON: result)
                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                            "portal": ASCOnlyOfficeApi.shared.baseUrl ?? "none",
                            "onDevice": false,
                            "type": "file",
                            "fileExt": file?.title.fileExtension().lowercased() ?? "none"
                            ]
                        )
                        completeon?(self, file, true, nil)
                    } else {
                        completeon?(self, nil, false, nil)
                    }
                }
        })
    }

    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        var params = params ?? [:]

        params += [
            "mime": "image/jpg"
        ]

        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        var params = params ?? [:]

        params += [
            "title": name
        ]

        upload(folder.id, data: data, overwrite: false, params: params) { progress, result, error, response in
            if let _ = result as? [String: Any] {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": ASCOnlyOfficeApi.shared.baseUrl ?? "none",
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
        ASCOnlyOfficeApi.post(
            String(format: ASCOnlyOfficeApi.apiCreateFolder, folder.id),
            parameters: ["title": name],
            completion: { [weak self] result, error, response in
                guard let strongSelf = self else { return }

                if error != nil {
                    completeon?(strongSelf, nil, false, ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!)))
                } else {
                    if let result = result as? [String: Any] {
                        let folder = ASCFolder(JSON: result)
                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                            "portal": self?.api.baseUrl ?? "none",
                            "onDevice": false,
                            "type": "folder"
                            ]
                        )
                        completeon?(strongSelf, folder, true, nil)
                    } else {
                        completeon?(strongSelf, nil, false, ASCProviderError(msg: ASCOnlyOfficeApi.errorMessage(by: response!)))
                    }
                }
            }
        )
    }

    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        var conflictItems: [Any] = []

        handler?(.begin, nil, nil)

        var folderIds: [String] = []
        var fileIds: [String] = []

        for entity in items {
            if let folder = entity as? ASCFolder {
                folderIds.append(folder.id)
            } else if let file = entity as? ASCFile {
                fileIds.append(file.id)
            }
        }

        var parameters: [String: Any] = [
            "destFolderId": folder.id
        ]

        if folderIds.count > 0 {
            parameters["folderIds"] = folderIds
        }

        if fileIds.count > 0 {
            parameters["fileIds"] = fileIds
        }

        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiBatchMove, parameters: parameters) { (result, error, response) in
            if error != nil {
                handler?(.error, nil, ASCOnlyOfficeApi.errorMessage(by: response!))
            } else {
                if let result = result as? [[String: Any]] {
                    // Return files only
                    for entity in result {
                        if let file = ASCFile(JSON: entity) {
                            conflictItems.append(file)
                        }
                    }

                    handler?(.end, conflictItems, nil)
                } else {
                    handler?(.end, nil, nil)
                }
            }
        }
    }

    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) {
        var cancel = false

        handler?(.begin, 0, nil, nil, &cancel)

        var folderIds: [String] = []
        var fileIds: [String] = []

        for entity in items {
            if let folder = entity as? ASCFolder {
                folderIds.append(folder.id)
            } else if let file = entity as? ASCFile {
                fileIds.append(file.id)
            }
        }

        var parameters: [String: Any] = [
            "destFolderId": folder.id,
            "conflictResolveType": overwrite ? 1 : 0 // Overwriting behavior: skip(0), overwrite(1) or duplicate(2)
        ]

        if folderIds.count > 0 {
            parameters["folderIds"] = folderIds
        }

        if fileIds.count > 0 {
            parameters["fileIds"] = fileIds
        }

        ASCOnlyOfficeApi.put(move ? ASCOnlyOfficeApi.apiBatchMove : ASCOnlyOfficeApi.apiBatchCopy, parameters: parameters) { (result, error, response) in
            if error != nil {
                handler?(.error, 1, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
            } else {
                var checkOperation: (()->Void)?
                checkOperation = {
                    ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiFileOperations) { (result, error, response) in
                        if error != nil {
                            handler?(.error, 1, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
                        } else {
                            if let result = result as? [Any], let entityFromResponse = result.first as? [String: Any] {
                                if let progressResponse = entityFromResponse["progress"] as? Int {
                                    handler?(.progress, Float(progressResponse) / 100.0, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)

                                    if progressResponse >= 100 {
                                        //                                            if let files = entityFromResponse["files"] as? [[String: Any]], files.count > 1, let file = ASCFile(JSON: files[1]) {
                                        //                                                handler?(.end, 1, file, nil, &cancel)
                                        //                                            }
                                        handler?(.end, 1, nil, nil, &cancel)
                                    } else {
                                        Thread.sleep(forTimeInterval: 1)
                                        checkOperation?()
                                    }
                                } else {
                                    handler?(.error, 1, nil, NSLocalizedString("Unknown API response.", comment: ""), &cancel)
                                }
                            }
                        }
                    }
                }
                checkOperation?()
            }
        }
    }

    // MARK: - Access

    func isRoot(folder: ASCFolder?) -> Bool {
        if let folder = folder {
            return folder.parentId == nil || folder.parentId == "0"
        }

        return false
    }
    
    func allowRead(entity: AnyObject?) -> Bool {
        if let file = entity as? ASCFile {
            return file.access != .restrict
        }

        if let folder = entity as? ASCFolder {
            return folder.access != .restrict
        }

        return false
    }

    func allowEdit(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file == nil && folder == nil {
            return false
        }

        guard let user = user else {
            return false
        }

        if user.isVisitor {
            return false
        }

        if let folder = folder {
            if isRoot(folder: folder) && folder.rootFolderType == .onlyofficeCommon && !user.isAdmin {
                return false
            }

            if isRoot(folder: folder) && folder.rootFolderType == .onlyofficeShare {
                return false
            }

            if isRoot(folder: folder) && folder.rootFolderType == .onlyofficeTrash {
                return false
            }

            if isRoot(folder: folder) && (folder.rootFolderType == .onlyofficeProjects || folder.rootFolderType == .onlyofficeBunch) {
                return false
            }
        }

        var access: ASCEntityAccess = ((file != nil) ? file?.access : folder?.access)!

        if let parentFolder = parentFolder, let folder = folder, folder.id == parentFolder.id {
            access = parentFolder.access
        }

        switch (access) {
        case .none, .readWrite, .review, .comment, .fillforms:
            return true
        default:
            return false
        }
    }

    func allowDelete(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file == nil && folder == nil {
            return false
        }
        
        if let file = file, file.isEditing {
            return false
        }

        guard let user = user else {
            return false
        }

        if user.isVisitor {
            return false
        }

        var access = (file != nil) ? file?.access : folder?.access

        if folder != nil && folder?.id == parentFolder?.id {
            access = parentFolder?.access
        }
        
        if [.restrict, .varies, .review, .comment, .fillforms].contains(access) {
            return false
        }

        if isRoot(folder: parentFolder) && (parentFolder?.rootFolderType == .onlyofficeBunch || parentFolder?.rootFolderType == .onlyofficeProjects) {
            return false
        }

        // Is root third-party directory
        if isRoot(folder: parentFolder) && folder?.isThirdParty == true {
            return false
        }

        let isProjectRoot = isRoot(folder: parentFolder) && (parentFolder?.rootFolderType == .onlyofficeBunch || parentFolder?.rootFolderType == .onlyofficeProjects)

        return (access == ASCEntityAccess.none
            || ((file != nil ? file?.rootFolderType == .onlyofficeCommon : folder?.rootFolderType == .onlyofficeCommon) && user.isAdmin)
            || (!isProjectRoot && (file != nil ? user.userId == file?.createdBy?.userId : user.userId == folder?.createdBy?.userId)))
    }
    
    func allowShare(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file == nil && folder == nil {
            return false
        }

        guard let user = user else {
            return false
        }

        if user.isVisitor {
            return false
        }

        var access = (file != nil) ? file?.access : folder?.access

        if folder != nil && folder?.id == parentFolder?.id {
            access = parentFolder?.access
        }
        
        if [.restrict, .varies, .review, .comment, .fillforms].contains(access) {
            return false
        }
        
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

        if let file = file, api.active {
            let fileExtension   = file.title.fileExtension().lowercased()
            let isPersonal      = (api.baseUrl?.contains(ASCConstants.Urls.portalPersonal)) ?? false
            let canRead         = allowRead(entity: file)
            let canEdit         = allowEdit(entity: file)
            let canDelete       = allowDelete(entity: file)
            let canShare        = allowShare(entity: file)
            let isTrash         = file.rootFolderType == .onlyofficeTrash
            let isShared        = file.rootFolderType == .onlyofficeShare
            let isProjects      = file.rootFolderType == .onlyofficeBunch || file.rootFolderType == .onlyofficeProjects
            let canOpenEditor   = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                ASCConstants.FileExtensions.spreadsheets.contains(fileExtension)
            let canPreview      = canOpenEditor ||
                ASCConstants.FileExtensions.presentations.contains(fileExtension) ||
                ASCConstants.FileExtensions.images.contains(fileExtension) ||
                fileExtension == "pdf"

            if isTrash {
                return [.delete, .restore]
            }

            entityActions.insert(.favarite)
            
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

            if canEdit && canOpenEditor && !(user?.isVisitor ?? false) && UIDevice.allowEditor {
                entityActions.insert(.edit)
            }

            if canRead && !isTrash {
                entityActions.insert(.download)
            }

            if canEdit && canShare && !isProjects && !isPersonal {
                entityActions.insert(.share)
            }

            if canEdit && !isShared && !(file.parent?.isThirdParty ?? false) {
                entityActions.insert(.duplicate)
            }

        }

        return entityActions
    }

    private func actions(for folder: ASCFolder?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let folder = folder, api.active {
            let isPersonal      = (api.baseUrl?.contains(ASCConstants.Urls.portalPersonal)) ?? false
            let canRead         = allowRead(entity: folder)
            let canEdit         = allowEdit(entity: folder)
            let canDelete       = allowDelete(entity: folder)
            let canShare        = allowShare(entity: folder)
            let isProjects      = folder.rootFolderType == .onlyofficeBunch || folder.rootFolderType == .onlyofficeProjects
            let isThirdParty    = folder.isThirdParty && (folder.parent?.parentId == nil || folder.parent?.parentId == "0")

            if folder.rootFolderType == .onlyofficeTrash {
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

            if canEdit && canShare && !isPersonal && !isProjects {
                entityActions.insert(.share)
            }

            if canDelete {
                entityActions.insert(.delete)
            }

            if isThirdParty {
                entityActions.insert(.unmount)
            }
        }

        return entityActions
    }

    // MARK: - Helpers

    func absoluteUrl(from string: String?) -> URL? {
        return ASCOnlyOfficeApi.absoluteUrl(from: URL(string: string ?? ""))
    }

    private func errorInfo(by response: Any) -> [String: Any]? {
        if let response = response as? AFDataResponse<Any> {
            if let data = response.data {
                do {
                    return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                } catch {
                    log.error(error)
                }
            }
        }

        return nil
    }

    /// Handle network errors
    ///
    /// - Parameter error: Error
    func handleNetworkError(_ error: Error?) -> Bool {
        let endSessionLife = api.expires == nil || Date() > api.expires!

        var alertTitle = ASCLocalization.Error.unknownTitle
        var alertMessage = String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), api.baseUrl ?? "")

        if endSessionLife {
            alertTitle = NSLocalizedString("Your session has expired", comment: "")
            alertMessage = NSLocalizedString("Please re-login to renew your session.", comment: "")
        }

        let alertError = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle: .alert,
            tintColor: nil
        )

        alertError.addAction(
            UIAlertAction(
                title: NSLocalizedString("Logout", comment: ""),
                style: .destructive,
                handler: { action in
                    ASCUserProfileViewController.logout()
            })
        )

        if endSessionLife {
            alertError.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Renewal", comment: ""),
                    style: .cancel,
                    handler: { [weak self] action in
                        let currentAccout = ASCAccountsManager.shared.get(by: self?.api.baseUrl ?? "", email: self?.user?.email ?? "")
                        ASCUserProfileViewController.logout(renewAccount: currentAccout)
                })
            )
        } else {
            alertError.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Try Again", comment: ""),
                    style: .cancel,
                    handler: nil
                )
            )
        }

        if endSessionLife {
            if let topVC = UIApplication.topViewController() {
                if !(topVC is UIAlertController) {
                    topVC.present(alertError, animated: true, completion: nil)
                }
            }
        }

        return true
    }

    func errorMessage(by errorObject: Any) -> String {
        if let errorInfo = errorInfo(by: errorObject) {
            if let error = errorInfo["error"] as? [String: Any], let message = error["message"] as? String {
                return message
            }
        }

        return String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), api.baseUrl ?? "")
    }

    func errorBanner(_ error: String?) {
        if let localError = error {
            switch ASCOnlyOfficeError(rawValue: localError) {
            case .paymentRequired:
                ASCBanner.shared.showError(
                    title: ASCLocalization.Error.paymentRequiredTitle,
                    message: ASCLocalization.Error.paymentRequiredMsg
                )
            case .forbidden:
                ASCBanner.shared.showError(
                    title: ASCLocalization.Error.forbiddenTitle,
                    message: ASCLocalization.Error.forbiddenMsg
                )
            default:
                ASCBanner.shared.showError(
                    title: ASCLocalization.Error.unknownTitle,
                    message: localError
                )
            }
        }
    }

    // MARK: - Open file

    func open(file: ASCFile, viewMode: Bool = false) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let allowOpen       = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if allowOpen {
            let editMode = !viewMode && UIDevice.allowEditor
            let strongDelegate = delegate
            let openHandler = strongDelegate?.openProgressFile(title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
            let closeHandler = strongDelegate?.closeProgressFile(title: NSLocalizedString("Saving", comment: "Caption of the processing"))
            let favoriteHandler: ASCEditorManagerFavoriteHandler = { editorFile, complation in
                if let editorFile = editorFile {
                    self.favorite(editorFile, favorite: !editorFile.isFavorite) { provider, entity, success, error in
                        if let portalFile = entity as? ASCFile {
                            complation(portalFile.isFavorite)
                        } else {
                            complation(editorFile.isFavorite)
                        }
                    }
                }
            }
            let shareHandler: ASCEditorManagerShareHandler = { file in
                guard let file = file else { return }
                strongDelegate?.presentShareController(provider: self, entity: file)
            }

            if ASCEditorManager.shared.checkSDKVersion() {
                ASCEditorManager.shared.editCloud(
                    file,
                    viewMode: !editMode,
                    handler: openHandler,
                    closeHandler: closeHandler,
                    favoriteHandler: favoriteHandler,
                    shareHandler: shareHandler
                )
            } else {
                ASCEditorManager.shared.editFileLocally(for: self, file, viewMode: viewMode, handler: openHandler, closeHandler: closeHandler, lockedHandler: {
                    delay(seconds: 0.3) {
                        let isSpreadsheet  = file.title.fileExtension() == "xlsx"
                        let isPresentation = file.title.fileExtension() == "pptx"

                        var message = String(format: NSLocalizedString("This document is being edited. Do you want open %@ to view only?", comment: ""), file.title)

                        message = isSpreadsheet
                            ? String(format: NSLocalizedString("This spreadsheet is being edited. Do you want open %@ to view only?", comment: ""), file.title)
                            : message
                        message = isPresentation
                            ? String(format: NSLocalizedString("This presentation is being edited. Do you want open %@ to view only?", comment: ""), file.title)
                            : message

                        let alertController = UIAlertController.alert(
                            ASCConstants.Name.appNameShort,
                            message: message,
                            actions: [])
                            .okable() { _ in
                                let openHandler = strongDelegate?.openProgressFile(title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
                                let closeHandler = strongDelegate?.closeProgressFile(title: NSLocalizedString("Saving", comment: "Caption of the processing"))

                                ASCEditorManager.shared.editFileLocally(for: self, file, viewMode: true, handler: openHandler, closeHandler: closeHandler)
                            }
                            .cancelable()

                        if let topVC = ASCViewControllerManager.shared.topViewController {
                            topVC.present(alertController, animated: true, completion: nil)
                        }
                    }
                })
            }
        }
    }

    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?) {
        let title           = file.title
        let fileExt         = title.fileExtension().lowercased()
        let isPdf           = fileExt == "pdf"
        let isImage         = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo         = ASCConstants.FileExtensions.videos.contains(fileExt)
        let isAllowConvert  =
            ASCConstants.FileExtensions.documents.contains(fileExt) ||
            ASCConstants.FileExtensions.spreadsheets.contains(fileExt) ||
            ASCConstants.FileExtensions.presentations.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            ASCEditorManager.shared.browsePdfCloud(for: self, file, handler: openHandler)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else if isAllowConvert {
            // TODO: !!! Convert me
        } else {
            if let view = view {
                let openHandler = delegate?.openProgressFile(title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }
}
