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
    
    var category: ASCCategory?
    
    var id: String? {
        get {
            if
                let baseUrl = apiClient.baseURL?.absoluteString,
                let token = apiClient.token
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
                $0.id = OnlyofficeAPI.Path.Forlder.my
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
            return apiClient.isHttp2 ? "Bearer \(apiClient.token ?? "")" : apiClient.token
        }
    }

    var delegate: ASCProviderDelegate?
    
    internal var folder: ASCFolder?
    internal var fetchInfo: [String : Any?]?
    
    var apiClient: OnlyofficeApiClient {
        get {
            return OnlyofficeApiClient.shared
        }
    }
    
    init() {
        reset()
        OnlyofficeApiClient.reset()
    }

    init(baseUrl: String, token: String) {
        guard
            apiClient.baseURL?.absoluteString != baseUrl || apiClient.token != token
        else { return }
        
        reset()
        
        apiClient.baseURL = URL(string: baseUrl)
        apiClient.token = token
    }

    func copy() -> ASCFileProviderProtocol {
        let baseUrl = apiClient.baseURL?.absoluteString ?? ""
        let token = apiClient.token ?? ""
        
        let copy = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
        
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
        apiClient.cancelAll()
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue
        ]

        if let baseUrl = apiClient.baseURL?.absoluteString {
            info += ["baseUrl": baseUrl]
        }

        if let token = apiClient.token {
            info += ["token": token]
        }

        if let serverVersion = apiClient.serverVersion {
            info += ["serverVersion": serverVersion]
        }

        if let expires = apiClient.expires {
            let dateTransform = ASCDateTransform()
            info += ["expires": dateTransform.transformToJSON(expires) ?? ""]
        }

        if let capabilities = apiClient.capabilities {
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
                apiClient.capabilities = OnlyofficeCapabilities(JSON: capabilitiesJson)
            }

            let dateTransform = ASCDateTransform()
            
            apiClient.baseURL = URL(string: json["baseUrl"] as? String ?? "")
            apiClient.token = json["token"] as? String
            apiClient.serverVersion = json["serverVersion"] as? String
            apiClient.expires = dateTransform.transformFromJSON(json["expires"])
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
        // Fire update notification
        let postUpdate = {
            NotificationCenter.default.post(name: ASCConstants.Notifications.userInfoOnlyofficeUpdate, object: nil)
            ASCFileManager.storeProviders()
        }
        
        // Fetch photo of user
        let fetchPhoto: (ASCUser) -> Void = { [weak self] user in
            self?.apiClient.request(OnlyofficeAPI.Endpoints.People.photo(of: user)) { [weak self] response, error in
                defer {
                    postUpdate()
                    completeon?(true, nil)
                }
                
                if let photo = response?.result {
                    self?.user?.avatarRetina = photo.retina
                } else {
                    postUpdate()
                    completeon?(true, error)
                }
            }
        }
        
        // Fetch user
        apiClient.request(OnlyofficeAPI.Endpoints.People.me) { [weak self] response, error in
            if let user = response?.result {
                self?.user = user
                fetchPhoto(user)
            } else {
                completeon?(false, error)
            }
        }
    }

    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        completionHandler(ASCNetworkReachability.shared.isReachable && apiClient.active, nil)
    }

    /// Allow the redirection with a modified request
    ///
    /// - Parameter request: the original request
    /// - Returns: the modified request
    func modifyImageDownloader(request: URLRequest) -> URLRequest {
        var modifyRequest = request

        // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
        if let baseUrl = apiClient.baseURL?.absoluteString, URL(string: baseUrl)?.host == request.url?.host {
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

            strongSelf.apiClient.request(OnlyofficeAPI.Endpoints.Folders.path(of: folder), params) { [weak self] response, error in
                guard let strongSelf = self else {
                    completeon?(strongSelf, folder, false, error)
                    return
                }
                
                var currentFolder = folder
                
                if let path = response?.result {
                    strongSelf.total = path.total
                    
                    if let current = path.current {
                        currentFolder = current
                    }

                    if strongSelf.page == 0 {
                        strongSelf.items.removeAll()
                    }

                    let entities: [ASCEntity] = (path.folders + path.files).map { entitie in
                        if let folder = entitie as? ASCFolder {
                            folder.parent = currentFolder
                            return folder
                        } else if let file = entitie as? ASCFile {
                            file.parent = currentFolder
                            return file
                        }
                        return entitie
                    }

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
        if  let file = entity as? ASCFile {
            let fileExtension = file.title.fileExtension()
            let newTitle = fileExtension.isEmpty ? newName : String(format:"%@.%@", newName, fileExtension)
            
            apiClient.request(OnlyofficeAPI.Endpoints.Files.update(file: file), ["title": newTitle]) { response, error in
                if let file = response?.result {
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed.", comment: "")))
                }
            }
        } else if let folder = entity as? ASCFolder {
            apiClient.request(OnlyofficeAPI.Endpoints.Folders.update(folder: folder), ["title": newName]) { response, error in
                if let folder = response?.result {
                    completeon?(self, folder, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Rename failed.", comment: "")))
                }
            }
        }
    }
    
    func favorite(_ entity: ASCEntity, favorite: Bool, completeon: ASCProviderCompletionHandler?) {
        guard let file = entity as? ASCFile else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }
        
        if favorite {
            apiClient.request(OnlyofficeAPI.Endpoints.Files.addFavorite, ["fileIds" : [file.id]]) { response, error in
                if response?.result ?? false {
                    file.isFavorite = true
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Set favorite failed.", comment: "")))
                }
            }
        } else {
            apiClient.request(OnlyofficeAPI.Endpoints.Files.removeFavorite, ["fileIds" : [file.id]]) { response, error in
                if response?.result ?? false {
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
                    self.apiClient.request(OnlyofficeAPI.Endpoints.Sharing.removeSharingRights, parameters) { response, error in
                        defer { semaphore.signal() }
                        
                        if response?.result ?? false {
                            resultItems += entities.filter { folderIds.contains($0.id) }
                            resultItems += entities.filter { fileIds.contains($0.id) }
                        } else {
                            lastError = ASCProviderError(
                                msg: error?.localizedDescription ?? NSLocalizedString("Unable disconnect third party", comment: "")
                            )
                        }
                    }
                } else {
                    self.apiClient.request(OnlyofficeAPI.Endpoints.Operations.removeEntities, parameters) { response, error in
                        
                        if (response?.result?.count ?? 0) > 0 {
                            var checkOperation: (()->Void)?
                            checkOperation = {
                                self.apiClient.request(OnlyofficeAPI.Endpoints.Operations.list) {
                                    result, error in
                                    defer { semaphore.signal() }
                                    if let error = error {
                                        lastError = ASCProviderError(msg: error.localizedDescription)
                                    } else if let operation = result?.result?.first, let progress = operation.progress {
                                        if progress >= 100 {
                                            resultItems += entities.filter { folderIds.contains($0.id) }
                                            resultItems += entities.filter { fileIds.contains($0.id) }
                                        } else {
                                            Thread.sleep(forTimeInterval: 1)
                                            checkOperation?()
                                        }
                                    } else {
                                        lastError = ASCProviderError(msg: NetworkingError.invalidData.localizedDescription)
                                    }
                                }
                            }
                            checkOperation?()
                        } else {
                            lastError = ASCProviderError(
                                msg: error?.localizedDescription ?? NSLocalizedString("Unable delete items", comment: "")
                            )
                            semaphore.signal()
                        }
                    }
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

                    if isShareRoot {
                        self.apiClient.request(OnlyofficeAPI.Endpoints.Sharing.removeSharingRights) { response, error in
                            defer { semaphore.signal() }
                            
                            if response?.result ?? false {
                                resultItems += entities.filter { folderIds.contains($0.id) }
                                resultItems += entities.filter { fileIds.contains($0.id) }
                            } else {
                                lastError = ASCProviderError(
                                    msg:error?.localizedDescription ?? NSLocalizedString("Unable disconnect third party", comment: "")
                                )
                            }
                        }
                    } else {
                        self.apiClient.request(OnlyofficeAPI.Endpoints.ThirdPartyIntegration.remove(providerId: providerId)) { response, error in
                            defer { semaphore.signal() }
                            
                            if let folderId = response?.result {
                                let folder = ASCFolder()
                                folder.id = folderId
                                resultItems.append(folder)
                            } else {
                                lastError = ASCProviderError(
                                    msg:error?.localizedDescription ?? NSLocalizedString("Unable disconnect third party", comment: "")
                                )
                            }
                        }
                    }
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

    func emptyTrash(completeon: ASCProviderCompletionHandler?) {
        apiClient.request(OnlyofficeAPI.Endpoints.Operations.emptyTrash) { result, error in
            completeon?(self, nil, error == nil, error)
        }
    }
    
    func download(_ path: String, to: URL, processing: @escaping NetworkProgressHandler) {
        apiClient.download(path, to, processing)
    }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        let file = ASCFile()
        file.id = path
        
        var uploadParams = params ?? [:]
        let mime = uploadParams["mime"] as? String

        uploadParams.removeAll(keys: ["mime"])
        
        apiClient.upload(OnlyofficeAPI.Endpoints.Files.saveEditing(file: file), data, uploadParams, mime) { response, progress, error in
            processing(response?.result, progress, error)
        }
    }
        
    func upload(
        _ path: String,
        data: Data,
        overwrite: Bool,
        params: [String: Any]?,
        processing: @escaping NetworkProgressHandler) {
        
        let mime = params?["mime"] as? String ?? "application/octet-stream"
        let fileName = params?["title"] as? String ?? ""
        
        /// Upload method using multipart/form-data
        apiClient.request(OnlyofficeAPI.Endpoints.Uploads.upload(in: path)) { multipartFormData in
            multipartFormData.append(data, withName: "file", fileName: fileName, mimeType: mime)
        } _: { response, progress, error  in
            processing(response?.result, progress, error)
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        let fileTitle = name + "." + fileExtension

        apiClient.request(OnlyofficeAPI.Endpoints.Files.create(in: folder), ["title": fileTitle]) { result, error in
            if let error = error {
                completeon?(self, nil, false, error)
            } else if let file = result?.result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                    ASCAnalytics.Event.Key.fileExt: file.title.fileExtension().lowercased()
                    ]
                )
                completeon?(self, file, true, nil)
            } else {
                completeon?(self, nil, false, NetworkingError.invalidData)
            }
        }
    }

    func createImage(
        _ name: String,
        in folder: ASCFolder,
        data: Data,
        params: [String: Any]?,
        processing: @escaping NetworkProgressHandler)
    {
        var params = params ?? [:]

        params += [
            "mime": "image/jpg"
        ]

        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(
        _ name: String,
        in folder: ASCFolder,
        data: Data,
        params: [String: Any]?,
        processing: @escaping NetworkProgressHandler)
    {
        var params = params ?? [:]

        params += [
            "title": name
        ]

        upload(folder.id, data: data, overwrite: false, params: params) { result, progress, error in
            if let _ = result as? ASCFile {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                    ASCAnalytics.Event.Key.fileExt: name.fileExtension()
                    ]
                )
            }
            processing(result, progress, error)
        }
    }

    func createFolder(
        _ name: String,
        in folder: ASCFolder,
        params: [String: Any]?,
        completeon: ASCProviderCompletionHandler?)
    {
        apiClient.request(OnlyofficeAPI.Endpoints.Folders.create(in: folder), ["title": name]) { result, error in
            if let error = error {
                completeon?(self, nil, false, error)
            } else if let folder = result?.result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.folder
                    ]
                )
                completeon?(self, folder, true, nil)
            } else {
                completeon?(self, nil, false, NetworkingError.invalidData)
//                completeon?(self, nil, false, ASCProviderError(NetworkingError.invalidData))
            }
        }
    }

    func chechTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        handler: ASCEntityHandler? = nil)
    {
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

        apiClient.request(OnlyofficeAPI.Endpoints.Operations.check, parameters) { result, error in
            if let error = error {
                handler?(.error, nil, error.localizedDescription)
            } else if let files = result?.result {
                handler?(.end, files, nil)
            } else {
                handler?(.error, nil, NetworkingError.invalidData.localizedDescription)
            }
        }
    }

    func transfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool,
        overwrite: Bool,
        handler: ASCEntityProgressHandler?)
    {
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

        apiClient.request(move ? OnlyofficeAPI.Endpoints.Operations.move : OnlyofficeAPI.Endpoints.Operations.copy, parameters) { [weak apiClient] result, error in
            if let error = error {
                handler?(.error, 1, nil, error.localizedDescription, &cancel)
            } else {
                var checkOperation: (()->Void)?
                checkOperation = {
                    apiClient?.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error.localizedDescription, &cancel)
                        } else if let operation = result?.result?.first, let progress = operation.progress {
                            if progress >= 100 {
                                handler?(.end, 1, nil, nil, &cancel)
                            } else {
                                Thread.sleep(forTimeInterval: 1)
                                checkOperation?()
                            }
                        } else {
                            handler?(.error, 1, nil, NetworkingError.invalidData.localizedDescription, &cancel)
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
            
            if isRoot(folder: folder) && folder.rootFolderType == .onlyofficeFavorites {
                return false
            }
            
            if isRoot(folder: folder) && folder.rootFolderType == .onlyofficeRecent {
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

        if category?.folder?.rootFolderType == .onlyofficeFavorites {
            return false
        }
        
        if category?.folder?.rootFolderType == .onlyofficeRecent {
            return false
        }
        
        if category?.folder?.rootFolderType == .onlyofficeShare {
            return true
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

        if let file = file, apiClient.active {
            let fileExtension   = file.title.fileExtension().lowercased()
            let canRead         = allowRead(entity: file)
            let canEdit         = allowEdit(entity: file)
            let canDelete       = allowDelete(entity: file)
            let canShare        = allowShare(entity: file)
            let isTrash         = file.rootFolderType == .onlyofficeTrash
            let isShared        = file.rootFolderType == .onlyofficeShare
            let isProjects      = file.rootFolderType == .onlyofficeBunch || file.rootFolderType == .onlyofficeProjects
            let canOpenEditor   = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                ASCConstants.FileExtensions.spreadsheets.contains(fileExtension) ||
                ASCConstants.FileExtensions.forms.contains(fileExtension)
            let canPreview      = canOpenEditor ||
                ASCConstants.FileExtensions.presentations.contains(fileExtension) ||
                ASCConstants.FileExtensions.images.contains(fileExtension) ||
                fileExtension == "pdf"
            
            let isFavoriteCategory = category?.folder?.rootFolderType == .onlyofficeFavorites
            let isRecentCategory   = category?.folder?.rootFolderType == .onlyofficeRecent

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

            if canEdit && canShare && !isProjects {
                entityActions.insert(.share)
            }

            if canEdit && !isShared && !isFavoriteCategory && !isRecentCategory && !(file.parent?.isThirdParty ?? false) {
                entityActions.insert(.duplicate)
            }

        }

        return entityActions
    }

    private func actions(for folder: ASCFolder?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let folder = folder, apiClient.active {
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

            if canEdit && canShare && !isProjects {
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
        return OnlyofficeApiClient.absoluteUrl(from: URL(string: string ?? ""))
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
        let endSessionLife = apiClient.expires == nil || Date() > apiClient.expires!

        var alertTitle = ASCLocalization.Error.unknownTitle
        var alertMessage = String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), apiClient.baseURL?.absoluteString ?? "")

        if endSessionLife {
            alertTitle = NSLocalizedString("Your session has expired", comment: "")
            alertMessage = NSLocalizedString("Please re-login to renew your session.", comment: "")
            errorFeedback(title: alertTitle, message: alertMessage)
        } else if let error = error as? NetworkingError {
            switch error {
            case .apiError(let error):
                if let error = error as? OnlyofficeServerError {
                    switch error {
                    case .unauthorized:
                        errorFeedback(title: error.localizedDescription, message: NSLocalizedString("Please re-login to renew your session.", comment: ""))
                    case .unknown(let message):
                        errorFeedback(title: alertTitle, message: message ?? alertMessage, allowRenew: false)
                    default:
                        errorFeedback(title: alertTitle, message: error.localizedDescription, allowRenew: false)
                    }
                }
            default:
                errorFeedback(title: alertTitle, message: error.localizedDescription, allowRenew: false)
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

        return String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), apiClient.baseURL?.absoluteString ?? "")
    }

    func errorBanner(_ error: Error?) {
        var title = ASCLocalization.Error.unknownTitle
        var message = error?.localizedDescription ?? ""
        
        if let error = error as? NetworkingError {
            message = error.localizedDescription
            
            switch error {
            case .apiError(let error):
                if let onlyofficeError = error as? OnlyofficeServerError {
                    switch onlyofficeError {
                    case .paymentRequired:
                        title = ASCLocalization.Error.paymentRequiredTitle
                        message = ASCLocalization.Error.paymentRequiredMsg
                    case.forbidden:
                        title = ASCLocalization.Error.forbiddenTitle
                        message = ASCLocalization.Error.forbiddenMsg
                    default:
                        message = error.localizedDescription
                    }
                }
            default:
                break
            }
        }
        
        ASCBanner.shared.showError(
            title: title,
            message: message
        )
    }
    
    func errorFeedback(title: String, message: String, allowRenew: Bool = true) {
        let alertError = UIAlertController(
            title: title,
            message: message,
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

        if allowRenew {
            alertError.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Renewal", comment: ""),
                    style: .cancel,
                    handler: { [weak self] action in
                        let currentAccout = ASCAccountsManager.shared.get(by: self?.apiClient.baseURL?.absoluteString ?? "", email: self?.user?.email ?? "")
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

        // TODO: Check if onlyoffice provider in front
        if let topVC = UIApplication.topViewController() {
            if !(topVC is UIAlertController) {
                topVC.present(alertError, animated: true, completion: nil)
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
            let openHandler = strongDelegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
            let closeHandler = strongDelegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))
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
                                let openHandler = strongDelegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
                                let closeHandler = strongDelegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))

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
            ASCConstants.FileExtensions.presentations.contains(fileExt) ||
            ASCConstants.FileExtensions.forms.contains(fileExt)

        if isPdf {
            let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
            ASCEditorManager.shared.browsePdfCloud(for: self, file, handler: openHandler)
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else if isAllowConvert {
            // TODO: !!! Convert me
        } else {
            if let view = view {
                let openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }
}
