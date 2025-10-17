//
//  ASCOnlyofficeProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Alamofire
import FileKit
import Firebase
import MBProgressHUD
import UIKit

class ASCOnlyofficeProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {
    typealias ASCEntityId = String

    var category: ASCCategory?

    var id: String? {
        if
            let baseUrl = apiClient.baseURL?.absoluteString,
            let token = apiClient.token
        {
            return (baseUrl + token).md5
        }
        return nil
    }

    var type: ASCFileProviderType {
        return .onlyoffice
    }

    var rootFolder: ASCFolder {
        return {
            $0.title = ASCOnlyofficeCategory.title(of: .user)
            $0.rootFolderType = .user
            $0.id = OnlyofficeAPI.Path.Folder.my
            return $0
        }(ASCFolder())
    }

    var items: [ASCEntity] = []

    private var itemsBeforeEditingOrder = [ASCEntity]()
    private var itemsIdsWithChangedOrderIndex = Set<ASCEntityId>()

    var page: Int = 0
    var pageSize: Int = 20
    var total: Int = 0
    var user: ASCUser?
    var authorization: String? {
        return apiClient.isHttp2 ? "Bearer \(apiClient.token ?? "")" : apiClient.token
    }

    var delegate: ASCProviderDelegate?
    var filterController: ASCFiltersControllerProtocol?

    var folder: ASCFolder? {
        didSet {
            if Thread.current.isMainThread {
                setFiltersController()
            } else {
                DispatchQueue.main.sync {
                    setFiltersController()
                }
            }
        }
    }

    var fetchInfo: [String: Any?]?

    var apiClient: OnlyofficeApiClient {
        return externalApiClient ?? OnlyofficeApiClient.shared
    }

    private var externalApiClient: OnlyofficeApiClient?

    var isRecentCategory: Bool { category?.folder?.rootFolderType == .recent }

    var contentTypes: [ASCFiletProviderContentType] {
        let defaultTypes: [ASCFiletProviderContentType] = [.files, .folders, .documents, .spreadsheets, .presentations, .images]
        if let folder = folder, isRoot(folder: folder), ASCOnlyofficeCategory.hasDocSpaceRootRoomsList(type: folder.rootFolderType) {
            return [.public, .custom, .collaboration, .fillingForms]
        }
        return isRecentCategory ? defaultTypes.filter { $0 != .folders } : defaultTypes
    }

    var isInDocSpaceCategory: Bool {
        guard let folder = folder else { return false }
        return isInDocSpaceCategory(folder: folder)
    }

    // MARK: Dependencies

    let sharedService: NetworkManagerSharedSettingsProtocol = NetworkManagerSharedSettings()

    // MRK: Init

    init() {
        reset()

        if externalApiClient == nil {
            apiClient.reset()
        }
    }

    init(baseUrl: String, token: String) {
        guard
            apiClient.baseURL?.absoluteString != baseUrl || apiClient.token != token
        else { return }

        reset()

        if externalApiClient == nil {
            apiClient.baseURL = URL(string: baseUrl)
            apiClient.token = token
        }
    }

    init(apiClient: OnlyofficeApiClient) {
        externalApiClient = apiClient
    }

    func title(folder: ASCFolder?) -> String? {
        if folder?.isRoot == true, let rootFolderType = folder?.rootFolderType {
            return ASCOnlyofficeCategory.title(of: rootFolderType)
        } else {
            return folder?.title
        }
    }

    func setFiltersController() {
        guard let folder = folder, filterController == nil else { return }
        filterController = makeFilterController(folder: folder)
    }

    func makeFilterController(folder: ASCFolder) -> ASCFiltersControllerProtocol {
        switch filterControllerType(forFolder: folder) {
        case .documents:
            return ASCOnlyOfficeFiltersController(
                builder: ASCFiltersCollectionViewModelBuilder(),
                filtersViewController: ASCFiltersViewController(),
                itemsCount: 0
            )
        case .docspace:
            return ASCDocSpaceFiltersController(builder: ASCFiltersCollectionViewModelBuilder(),
                                                filtersViewController: ASCFiltersViewController(),
                                                itemsCount: 0)
        case .docspaceRooms:
            return ASCDocSpaceRoomsFiltersController(
                builder: ASCFiltersCollectionViewModelBuilder(),
                filtersViewController: ASCFiltersViewController(),
                itemsCount: 0
            )
        }
    }

    fileprivate func filterControllerType(forFolder folder: ASCFolder) -> FilterControllerType {
        guard ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) else { return .documents }
        guard folder.isRoomListFolder else { return .docspace }
        return .docspaceRooms
    }

    func copy() -> ASCFileProviderProtocol {
        let copy: ASCOnlyofficeProvider

        if let externalApiClient = externalApiClient {
            copy = ASCOnlyofficeProvider(apiClient: externalApiClient)
        } else {
            let baseUrl = apiClient.baseURL?.absoluteString ?? ""
            let token = apiClient.token ?? ""
            copy = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
        }

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
        apiClient.cancelAll()
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue,
        ]

        if let baseUrl = apiClient.baseURL?.absoluteString {
            info += ["baseUrl": baseUrl]
        }

        if let token = apiClient.token {
            info += ["token": token]
        }

        if let expires = apiClient.expires {
            let dateTransform = ASCDateTransform()
            info += ["expires": dateTransform.transformToJSON(expires) ?? ""]
        }

        if let serverVersion = apiClient.serverVersion {
            info += ["serverVersion": serverVersion.toJSON()]
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

            if externalApiClient == nil {
                if let capabilitiesJson = json["capabilities"] as? [String: Any] {
                    apiClient.capabilities = OnlyofficeCapabilities(JSON: capabilitiesJson)
                }

                if let versions = json["serverVersion"] as? [String: Any] {
                    apiClient.serverVersion = OnlyofficeVersion(JSON: versions)
                }
                let dateTransform = ASCDateTransform()

                apiClient.baseURL = URL(string: json["baseUrl"] as? String ?? "")
                apiClient.token = json["token"] as? String
                apiClient.expires = dateTransform.transformFromJSON(json["expires"])
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
            guard let self else { return }

            let page = (parameters["page"] as? Int) ?? self.page + 1
            let startIndex = (parameters["startIndex"] as? Int) ?? self.page * self.pageSize
            let count = (parameters["count"] as? Int) ?? self.pageSize
            let total = (parameters["total"] as? Int) ?? self.total

            if total < startIndex {
                self.total = self.items.count
                completeon?(self, self.folder, false, ASCProviderError(msg: NSLocalizedString("Invalid server data.", comment: "")))
                return
            }

            var params: [String: Any] = [
                "page": page,
                "startIndex": startIndex,
                "count": count,
            ]

            if let searchArea = searchArea(for: folder) {
                params["searchArea"] = searchArea
            }

            /// Search
            if let search = parameters["search"] as? [String: Any] {
                params["filterBy"] = "title"
                params["filterOp"] = "contains"
                params["filterValue"] = (search["text"] as? String ?? "").trimmed
            }

            /// Sort
            self.fetchInfo = parameters

            if let sort = parameters["sort"] as? [String: Any] {
                if let sortBy = sort["type"] as? String, sortBy.length > 0 {
                    params["sortBy"] = sortBy
                }

                if let sortOrder = sort["order"] as? String, sortOrder.length > 0 {
                    params["sortOrder"] = sortOrder
                }
            }

            /// Filter
            var hasFilters = false
            if let filters = parameters["filters"] as? [String: Any] {
                hasFilters = true
                params.merge(filters, uniquingKeysWith: { current, _ in current })
            }

            let endpoint: Endpoint<OnlyofficeResponse<OnlyofficePath>> = {
                if folder.isRoomListFolder {
                    return OnlyofficeAPI.Endpoints.Folders.path(of: ASCFolder.onlyofficeRoomSharedFolder)
                }

                guard hasFilters, folder.isRoomListFolder else {
                    return OnlyofficeAPI.Endpoints.Folders.path(of: folder)
                }

                return OnlyofficeAPI.Endpoints.Folders.roomsPath()
            }()

            self.apiClient.request(endpoint, params) { [weak self] response, error in
                guard let self else { return }

                var currentFolder = folder

                if let path = response?.result {
                    self.total = path.total

                    if let current = path.current {
                        currentFolder = current

                        if currentFolder.parent == nil {
                            currentFolder.parentId = folder.parentId
                            currentFolder.parent = folder.parent
                        }
                    }

                    if self.page == 0 {
                        self.items.removeAll()
                    }

                    let entities: [ASCEntity] = (path.folders + path.files).map { entitie in
                        if let folder = entitie as? ASCFolder {
                            folder.parent = currentFolder
                            self.allowLeave(folder: folder) { isAllowed in
                                if isAllowed {
                                    folder.isCanLeaveRoom = true
                                }
                            }
                            return folder
                        } else if let file = entitie as? ASCFile {
                            file.parent = currentFolder
                            return file
                        }
                        return entitie
                    }.sorted(by: { v1, v2 in
                        guard let orderV1 = Int(v1.orderIndex ?? ""),
                              let orderV2 = Int(v2.orderIndex ?? "")
                        else { return false }
                        return orderV1 < orderV2
                    })

                    self.items += entities

                    completeon?(self, currentFolder, true, nil)
                } else {
                    completeon?(self, currentFolder, false, error)
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
                    guard let self else { return }
                    completeon?(self, folder, false, error)
                }
            }
        }
    }

    func searchArea(for folder: ASCFolder) -> String? {
        guard ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) else { return nil }

        // List of Room Templates
        if folder.isRoot, folder.rootFolderType == .roomTemplates {
            return ASCOnlyofficeCategory.searchArea(of: folder.rootFolderType)
        }

        if let searchArea = ASCOnlyofficeCategory.searchArea(of: folder.rootFolderType) {
            return searchArea
        }

        return nil
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

    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        if let file = entity as? ASCFile {
            let fileExtension = file.title.fileExtension()
            let newTitle = fileExtension.isEmpty ? newName : String(format: "%@.%@", newName, fileExtension)

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
            apiClient.request(OnlyofficeAPI.Endpoints.Files.addFavorite, ["fileIds": [file.id]]) { response, error in
                if response?.result ?? false {
                    file.isFavorite = true
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Set favorite failed.", comment: "")))
                }
            }
        } else {
            apiClient.request(OnlyofficeAPI.Endpoints.Files.removeFavorite, ["fileIds": [file.id]]) { response, error in
                if response?.result ?? false {
                    file.isFavorite = false
                    completeon?(self, file, true, nil)
                } else {
                    completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Set favorite failed.", comment: "")))
                }
            }
        }
    }

    func fillFormDidSubmit(_ entity: ASCEntity, fillingSessionId: String, completeon: ASCProviderCompletionHandler?) {
        guard let file = entity as? ASCFile else {
            completeon?(self, nil, false, ASCProviderError(msg: NSLocalizedString("Unknown item type.", comment: "")))
            return
        }

        completeon?(self, file, true, nil)

        let requestModel = CompleteFormRequestModel(fillingSessionId: fillingSessionId)

        // Handle send form
        apiClient.request(OnlyofficeAPI.Endpoints.Files.fillFormDidSend(), requestModel.dictionary) { result, error in
            guard let topVC = UIApplication.topViewController() else { return }
            MBProgressHUD.hide(for: topVC.view, animated: true)

            if let error = error {
                topVC.showAlert(
                    title: NSLocalizedString("Error", comment: ""),
                    message: error.localizedDescription
                )
                return
            }

            guard let responce = result?.result else {
                return
            }

            let checkRedyFormHandler = { [weak self] in
                guard let self else { return }

                let doneFolder = items
                    .compactMap { $0 as? ASCFolder }
                    .first(where: { $0.type == .readyFormFolder })

                guard let doneFolder,
                      let topMostViewController = ASCViewControllerManager.shared.rootController?.topMostViewController(),
                      let topController = topMostViewController as? ASCDocumentsViewController
                else {
                    return
                }
                let documentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)

                documentsVC.provider = self.copy()
                documentsVC.provider?.cancel()
                documentsVC.provider?.reset()
                documentsVC.folder = doneFolder
                documentsVC.title = doneFolder.title
                topController.navigationController?.pushViewController(documentsVC, animated: true)
            }

            let vc = CreateFormCompletedRootViewController(
                formModel: FormModel(
                    form: responce.completedForm ?? ASCFile(),
                    authorName: responce.manager?.displayName ?? "",
                    authorEmail: responce.manager?.email ?? "",
                    formNumber: responce.formNumber,
                    authorAvatar: responce.manager?.avatar ?? ""
                ),
                onCheckReadyForm: checkRedyFormHandler
            )

            topVC.present(vc, animated: true)
        }

        if let topVC = UIApplication.topViewController() {
            MBProgressHUD.showAdded(to: topVC.view, animated: true)
        }
    }

    func markAsRead(_ entities: [ASCEntity], completeon: ASCProviderCompletionHandler?) {
        var params: [String: [String]] = [:]

        let fileIds = entities
            .filter { $0 is ASCFile }
            .map { $0.id }

        let folderIds = entities
            .filter { $0 is ASCFolder }
            .map { $0.id }

        if !fileIds.isEmpty {
            params["fileIds"] = fileIds
        }

        if !folderIds.isEmpty {
            params["folderIds"] = folderIds
        }

        apiClient.request(OnlyofficeAPI.Endpoints.Operations.markAsRead, params) { response, error in
            if let error = error {
                completeon?(self, nil, false, error)
            } else {
                completeon?(self, entities, true, nil)
            }
        }
    }

    func delete(_ entities: [ASCEntity], from folder: ASCFolder, move: Bool?, completeon: ASCProviderCompletionHandler?) {
        let isShareRoot = folder.rootFolderType == .share && (folder.parentId == nil || folder.parentId == "0")
        var folderIds: [String] = []
        var cloudFolderIds: [String] = []
        var fileIds: [String] = []
        let currentFolder = folder

        var parameters: [String: Any] = [:]

        if folder.isRoot, folder.rootFolderType == .archive {
            parameters["deleteAfter"] = true
            parameters["immediately"] = true
        }

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
                            var checkOperation: (() -> Void)?
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
                                    } else if !(folder.rootFolderType == .archive && response?.statusCode == 200) {
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
            if let providerFolder = entities.first(where: { $0.id == cloudFolderId }) as? ASCFolder,
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
                                    msg: error?.localizedDescription ?? NSLocalizedString("Unable disconnect third party", comment: "")
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
                                    msg: error?.localizedDescription ?? NSLocalizedString("Unable disconnect third party", comment: "")
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

            DispatchQueue.main.async {
                completeon?(strongSelf, resultItems, resultItems.count > 0, lastError)
            }
        }
    }

    func emptyTrash(completeon: ASCProviderCompletionHandler?) {
        apiClient.request(OnlyofficeAPI.Endpoints.Operations.emptyTrash) { result, error in
            completeon?(self, nil, error == nil, error)
        }
    }

    func download(_ path: String, to: URL, range: Range<Int64>? = nil, processing: @escaping NetworkProgressHandler) {
        apiClient.download(path, to, range, processing)
    }

    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        let file = ASCFile()
        file.id = path

        var uploadParams = params ?? [:]
        let fileName = uploadParams["title"] as? String
        let mime = uploadParams["mime"] as? String

        uploadParams.removeAll(keys: ["mime"])

        if let docspaceVersion = apiClient.serverVersion?.docSpace, docspaceVersion.isVersion(greaterThanOrEqualTo: "3.1.0") {
            apiClient.request(OnlyofficeAPI.Endpoints.Files.saveEditing(file: file)) { multipartFormData in
                multipartFormData.append(data, withName: "file", fileName: fileName, mimeType: mime)
            } _: { response, progress, error in
                processing(response?.result, progress, error)
            }
        } else {
            apiClient.upload(OnlyofficeAPI.Endpoints.Files.saveEditing(file: file), data, uploadParams, mime) { response, progress, error in
                processing(response?.result, progress, error)
            }
        }
    }

    func upload(
        _ path: String,
        data: Data,
        overwrite: Bool,
        params: [String: Any]?,
        processing: @escaping NetworkProgressHandler
    ) {
        let mime = params?["mime"] as? String ?? "application/octet-stream"
        let fileName = params?["title"] as? String ?? ""

        /// Upload method using multipart/form-data
        apiClient.request(OnlyofficeAPI.Endpoints.Uploads.upload(in: path)) { multipartFormData in
            multipartFormData.append(data, withName: "file", fileName: fileName, mimeType: mime)
        } _: { response, progress, error in
            processing(response?.result, progress, error)
        }
    }

    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        let fileTitle = name + "." + fileExtension

        apiClient.request(OnlyofficeAPI.Endpoints.Files.create(in: folder), ["title": fileTitle]) { result, error in
            if let error {
                completeon?(self, nil, false, error)
            } else if let file = result?.result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: self.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                    ASCAnalytics.Event.Key.fileExt: file.title.fileExtension().lowercased(),
                ])
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
        processing: @escaping NetworkProgressHandler
    ) {
        var params = params ?? [:]

        params += [
            "mime": "image/jpg",
        ]

        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    func createFile(
        _ name: String,
        in folder: ASCFolder,
        data: Data,
        params: [String: Any]?,
        processing: @escaping NetworkProgressHandler
    ) {
        var params = params ?? [:]

        params += [
            "title": name,
        ]

        upload(folder.id, data: data, overwrite: false, params: params) { [weak self] result, progress, error in
            if let _ = result as? ASCFile {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: self?.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.file,
                    ASCAnalytics.Event.Key.fileExt: name.fileExtension(),
                ])
            }
            processing(result, progress, error)
        }
    }

    func createFolder(
        _ name: String,
        in folder: ASCFolder,
        params: [String: Any]?,
        completeon: ASCProviderCompletionHandler?
    ) {
        apiClient.request(OnlyofficeAPI.Endpoints.Folders.create(in: folder), ["title": name]) { result, error in
            if let error = error {
                completeon?(self, nil, false, error)
            } else if let createdFolder = result?.result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    ASCAnalytics.Event.Key.portal: self.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: false,
                    ASCAnalytics.Event.Key.type: ASCAnalytics.Event.Value.folder,
                ])
                createdFolder.parent = folder
                completeon?(self, createdFolder, true, nil)
            } else {
                completeon?(self, nil, false, NetworkingError.invalidData)
            }
        }
    }

    func chechTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        handler: ASCEntityHandler? = nil
    ) {
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
            "destFolderId": folder.id,
        ]

        if folderIds.count > 0 {
            parameters["folderIds"] = folderIds
        }

        if fileIds.count > 0 {
            parameters["fileIds"] = fileIds
        }

        apiClient.request(OnlyofficeAPI.Endpoints.Operations.check, parameters) { result, error in
            if let error = error {
                handler?(.error, nil, error)
            } else if let files = result?.result {
                handler?(.end, files, nil)
            } else {
                handler?(.error, nil, NetworkingError.invalidData)
            }
        }
    }

    func transfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool,
        conflictResolveType: ConflictResolveType,
        contentOnly: Bool = false,
        handler: ASCEntityProgressHandler?
    ) {
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
            "conflictResolveType": conflictResolveType.rawValue,
        ]

        if folderIds.count > 0 {
            parameters["folderIds"] = folderIds
        }

        if fileIds.count > 0 {
            parameters["fileIds"] = fileIds
        }

        if contentOnly {
            parameters["content"] = true
        }

        apiClient.request(move ? OnlyofficeAPI.Endpoints.Operations.move : OnlyofficeAPI.Endpoints.Operations.copy, parameters) { [weak apiClient] result, error in
            if let error = error {
                handler?(.error, 1, nil, error, &cancel)
            } else {
                var checkOperation: (() -> Void)?
                checkOperation = {
                    apiClient?.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error, &cancel)
                        } else if let operation = result?.result?.first, let progress = operation.progress {
                            if let error = operation.error, !error.isEmpty {
                                handler?(.error, 1, nil, StringError(error), &cancel)
                            } else if progress >= 100 {
                                handler?(.end, 1, nil, nil, &cancel)
                            } else {
                                Thread.sleep(forTimeInterval: 1)
                                checkOperation?()
                            }
                        } else {
                            handler?(.error, 1, nil, NetworkingError.invalidData, &cancel)
                        }
                    }
                }
                checkOperation?()
            }
        }
    }

    // MARK: - Access

    func isInDocSpaceCategory(folder: ASCFolder?) -> Bool {
        guard let folder = folder else { return false }
        return ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType)
    }

    func isRoot(folder: ASCFolder?) -> Bool {
        guard let folder = folder else { return false }
        return folder.parentId == nil || folder.parentId == "0"
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

    func allowDuplicate(entity: ASCEntity?) -> Bool {
        guard let entity = entity else { return false }

        // Allow duplicate folders only in case folder - is room
        if let folder = entity as? ASCFolder {
            return folder.security.duplicate
                && folder.isRoom
                && !folder.isThirdParty
        }

        if let file = entity as? ASCFile {
            return file.security.duplicate
        }

        return false
    }

    func allowCreateRoomFrom(template: ASCFolder) -> Bool {
        return template.security.create && isDocspace && template.isTemplateRoom
    }

    func allowDownload(folder: ASCFolder?) -> Bool {
        return true
    }

    func allowLeave(folder: ASCFolder, completion: @escaping (Bool) -> Void) {
        var isOwnerInRoom: Bool = false
        var isAllowLeave: Bool = true

        apiClient.request(OnlyofficeAPI.Endpoints.Sharing.room(folder: folder, method: .get)) { result, error in
            if let error {
                log.error(error)
            } else if let users = result?.result {
                for entity in users {
                    if entity.user?.userId == self.user?.userId {
                        isOwnerInRoom = true
                        break
                    }
                }

                if !isOwnerInRoom, let userIsOwner = self.user?.isOwner, userIsOwner {
                    isAllowLeave = false
                }

                completion(isAllowLeave)
            }
        }
    }

    func allowSetCustomFilter(entity: ASCEntity?) -> Bool {
        guard let file = entity as? ASCFile else {
            return false
        }

        return file.security.customFilter && file.title.fileExtension() == ASCConstants.FileExtensions.xlsx
    }

    func allowCopy(entity: AnyObject?) -> Bool {
        guard let entity = entity as? ASCEntity, allowRead(entity: entity) else { return false }
        guard isInDocSpaceCategory else { return true }
        if let folder = entity as? ASCFolder {
            return folder.security.copyTo
        } else if let file = entity as? ASCFile {
            return file.security.copy
        }
        return false
    }

    func allowRename(entity: AnyObject?) -> Bool {
        guard let parentFolder = folder, ASCOnlyofficeCategory.isDocSpace(type: parentFolder.rootFolderType) else {
            return allowEdit(entity: entity)
        }
        if let file = entity as? ASCFile {
            return file.security.rename
        }
        if let folder = entity as? ASCFolder {
            return folder.security.rename
        }
        return false
    }

    func allowAdd(toFolder folder: ASCFolder?) -> Bool {
        guard let folder = folder, ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) else { return allowEdit(entity: folder) }
        if folder.rootFolderType == .user {
            return true
        }

        if folder.rootFolderType == .archive {
            return total > 0
        }

        return folder.security.create
    }

    func allowComment(entity: AnyObject?) -> Bool {
        guard let file = entity as? ASCFile else { return allowEdit(entity: entity) }
        return file.security.comment
    }

    func allowEdit(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file == nil, folder == nil {
            return false
        }

        guard let user = user else {
            return false
        }

        if user.isVisitor {
            if let currentFolder = self.folder, isInDocSpaceCategory(folder: currentFolder) {} else {
                return false
            }
        }

        if let folder = self.folder, folder.rootFolderType == .archive, !isRoot(folder: folder) {
            return false
        }

        if let folder = folder {
            if isRoot(folder: folder), folder.rootFolderType == .common, !user.isAdmin {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .share {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .trash {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .favorites {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .recent {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .projects || folder.rootFolderType == .bunch {
                return false
            }

            if isRoot(folder: folder), folder.rootFolderType == .user, ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) {
                return true
            }

            if folder.isRoomListFolder {
                return false
            }

            if folder.rootFolderType == .archive {
                return false
            }
        }

        let folderSecurity = folder?.security
        let fileSecurity = file?.security

        let securityAllowEdit: Bool = {
            if let fileSecurity {
                return (fileSecurity.edit && !fileSecurity.startFilling)
                    || fileSecurity.comment
                    || fileSecurity.fillForms
                    || fileSecurity.review
            } else {
                guard folder != nil else {
                    return fileSecurity?.edit == true
                }
                return folderSecurity?.read == true
                    && folderSecurity?.rename == true
                    && folderSecurity?.create == true
            }
        }()

        if isInDocSpaceCategory, !securityAllowEdit, folder?.rootFolderType != .user {
            return false
        }

        var access: ASCEntityAccess = ((file != nil) ? file?.access : folder?.access)!

        if let parentFolder = parentFolder, let folder = folder, folder.id == parentFolder.id {
            access = parentFolder.access
        }

        switch access {
        case .none, .readWrite, .review, .comment, .fillforms, .customFilter:
            if let folder = folder, isInDocSpaceCategory(folder: folder) || ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) {
                return securityAllowEdit || (isRoot(folder: folder) && folder.security.create)
            } else {
                return true
            }
        default:
            return false
        }
    }

    func allowDelete(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if let folder = folder, folder.isRoom, folder.rootFolderType != .archive {
            return false
        }

        if file == nil, folder == nil {
            return false
        }

        if let file = file, file.isEditing {
            return false
        }

        guard let user = user else {
            return false
        }

        if let file = file, let providerFolder = self.folder, ASCOnlyofficeCategory.isDocSpace(type: providerFolder.rootFolderType) {
            return file.security.delete
        }

        if user.isVisitor {
            return false
        }

        if let providerFolder = self.folder, providerFolder.rootFolderType == .archive, !isRoot(folder: providerFolder) {
            return false
        }

        if isRoot(folder: parentFolder), let folder = folder, folder.rootFolderType == .archive {
            return folder.security.delete
        }

        if let folder = folder, ASCOnlyofficeCategory.isDocSpace(type: folder.rootFolderType) {
            return folder.security.delete
        }

        var access = (file != nil) ? file?.access : folder?.access

        if folder != nil, folder?.id == parentFolder?.id {
            access = parentFolder?.access
        }

        if [.restrict, .varies, .review, .comment, .fillforms].contains(access) {
            return false
        }

        if isRoot(folder: parentFolder), parentFolder?.rootFolderType == .bunch || parentFolder?.rootFolderType == .projects {
            return false
        }

        // Is root third-party directory
        if isRoot(folder: parentFolder), folder?.isThirdParty == true {
            return false
        }

        if category?.folder?.rootFolderType == .favorites {
            return false
        }

        if category?.folder?.rootFolderType == .recent {
            return false
        }

        if category?.folder?.rootFolderType == .share {
            return true
        }

        let isProjectRoot = isRoot(folder: parentFolder) && (parentFolder?.rootFolderType == .bunch || parentFolder?.rootFolderType == .projects)

        return access == ASCEntityAccess.none
            || ((file != nil ? file?.rootFolderType == .common : folder?.rootFolderType == .common) && user.isAdmin)
            || (!isProjectRoot && (file != nil ? user.userId == file?.createdBy?.userId : user.userId == folder?.createdBy?.userId))
    }

    func allowShare(entity: AnyObject?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file == nil, folder == nil {
            return false
        }

        guard let user = user else {
            return false
        }

        if user.isVisitor {
            return false
        }

        var access = (file != nil) ? file?.access : folder?.access

        if folder != nil, folder?.id == parentFolder?.id {
            access = parentFolder?.access
        }

        if [.restrict, .varies, .review, .comment, .fillforms].contains(access) {
            return false
        }

        if let file, isDocspace, !file.canShare {
            return false
        }

        return true
    }

    func allowDragAndDrop(for entity: ASCEntity?) -> Bool {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        let parentFolder = file?.parent ?? folder?.parent

        if file != nil, parentFolder?.rootFolderType == .archive {
            return false
        }
        if let folder, folder.rootFolderType == .archive {
            return false
        }
        if let folder, folder.isRoom, folder.rootFolderType == .virtualRooms {
            return false
        }
        return true
    }

    func getAccess(for folder: ASCFolder?, password: String, completion: @escaping (Result<ASCFolder?, Error>) -> Void) {
        guard let folder, folder.passwordProtected, let token = folder.requestToken else {
            completion(.success(folder))
            return
        }

        let requestModel = SharePasswordRequestModel(password: password)
        let endpoint = OnlyofficeAPI.Endpoints.Sharing.password(token: token)
        apiClient.request(endpoint, requestModel.dictionary) { [apiClient] response, error in
            apiClient.savePasswordCookiesToHeaders(endpoint: endpoint)
            NetworkingClient.clearCookies(for: apiClient.url(path: endpoint.path))
            if response?.result != nil {
                folder.passwordProtected = false
                completion(.success(folder))
            } else if let error {
                completion(.failure(error))
            } else {
                completion(.failure(OnlyofficeServerError.unknown(message: NSLocalizedString("Couldn' get access", comment: ""))))
            }
        }
    }

    // MARK: Actions

    func actions(for entity: ASCEntity?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let file = entity as? ASCFile {
            entityActions = actions(for: file)
        } else if let folder = entity as? ASCFolder {
            entityActions = actions(for: folder)
        }

        return entityActions
    }

    func isTrash(for folder: ASCFolder?) -> Bool {
        folder?.rootFolderType == .trash
    }

    private func actions(for file: ASCFile?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let file, apiClient.active {
            let fileExtension = file.title.fileExtension().lowercased()
            let canRead = allowRead(entity: file)
            let canEdit = allowEdit(entity: file)
            let canDuplicate = allowDuplicate(entity: file)
            let canCopy = allowCopy(entity: file)
            let canDelete = allowDelete(entity: file)
            let canShare = allowShare(entity: file)
            let canDownload = !file.denyDownload
            let canMove = file.security.move
            let canRename = allowRename(entity: file)
            let isUserCategory = file.rootFolderType == .user
            let isRoomsCategory = file.rootFolderType == .virtualRooms
            let isTrash = file.rootFolderType == .trash
            let isShared = file.rootFolderType == .share
            let isProjects = file.rootFolderType == .bunch || file.rootFolderType == .projects
            let canShowVersion = file.version > 1
            let canSetCustomFilter = allowSetCustomFilter(entity: file)

            let canOpenEditor = ASCConstants.FileExtensions.documents.contains(fileExtension) ||
                ASCConstants.FileExtensions.spreadsheets.contains(fileExtension) ||
                ASCConstants.FileExtensions.forms.contains(fileExtension)
            var canPreview = canOpenEditor ||
                ASCConstants.FileExtensions.presentations.contains(fileExtension) ||
                ASCConstants.FileExtensions.images.contains(fileExtension) ||
                fileExtension == ASCConstants.FileExtensions.pdf

            // Workaround to disable the preview action in the fillform room
            if file.isForm, let roomType = file.parent?.roomType, roomType == .fillingForm,
               ASCConstants.FileExtensions.forms.contains(fileExtension) || ASCConstants.FileExtensions.pdf == fileExtension
            {
                canPreview = false
            }

            let isFavoriteCategory = category?.folder?.rootFolderType == .favorites

            if isTrash {
                return [.delete, .restore]
            }

            if let user = user, !user.isVisitor, !isInDocSpaceCategory(folder: folder) {
                entityActions.insert(.favarite)
            }

            if canRead, canDownload {
                entityActions.insert([.export])
            }

            if canCopy {
                entityActions.insert([.copy, .export])
            }

            if canDelete {
                if canMove {
                    entityActions.insert([.delete, .move])
                } else {
                    entityActions.insert([.delete])
                }
            }

            if canRename {
                entityActions.insert(.rename)
            }

            if canPreview {
                entityActions.insert(.open)
            }

            if file.isForm, isDocspace, isUserCategory,
               file.parent?.parentsFoldersOrCurrentContains(keyPath: \.roomType, value: .virtualData) != true,
               ASCConstants.FileExtensions.forms.contains(fileExtension) || ASCConstants.FileExtensions.pdf == fileExtension
               || file.parent?.parentsFoldersOrCurrentContains(keyPath: \.roomType, value: .fillingForm) == true
               || file.parent?.parentsFoldersOrCurrentContains(keyPath: \.type, value: .inProcessFormFolder) == true
               || file.security.fillForms
            {
                entityActions.insert(.fillForm)

                if canEdit {
                    entityActions.insert(.edit)
                }
            }

            if file.isForm,
               isDocspace,
               file.parent?.parentsFoldersOrCurrentContains(keyPath: \.roomType, value: .virtualData) == true,
               file.formFillingStatus == .yourTurn
            {
                entityActions.insert(.fillForm)
            }

            if canEdit, canOpenEditor, !(user?.isVisitor ?? false), UIDevice.allowEditor {
                entityActions.insert(.edit)
            }

            if canRead, !isTrash, canDownload {
                entityActions.insert(.download)
            }

            if canCopy, isDocspace, isUserCategory {
                entityActions.insert(.transformToRoom)
            }

            if canEdit, canShare, !isProjects, canDownload, !isInDocSpaceCategory(folder: folder) {
                entityActions.insert(.share)
            }

            if canDuplicate, !isShared, !isFavoriteCategory, !isRecentCategory, !(file.parent?.isThirdParty ?? false), canDownload {
                entityActions.insert(.duplicate)
            }

            if file.isNew {
                entityActions.insert(.new)
            }

            if isUserCategory, isDocspace, canShare {
                entityActions.insert(.docspaceShare)
                entityActions.insert(.copySharedLink)
            }

            if isRoomsCategory, isDocspace, file.security.copyLink {
                entityActions.insert(.copySharedLink)
            }

            if file.security.startFilling {
                entityActions.insert(.startFilling)
            }

            if file.security.fillingStatus {
                entityActions.insert(.fillingStatus)
            }

            if canShowVersion {
                entityActions.insert(.showVersionsHistory)
            }

            if canSetCustomFilter {
                entityActions.insert(.setCustomFilter)
            }
        }

        return entityActions
    }

    private func actions(for folder: ASCFolder?) -> ASCEntityActions {
        var entityActions: ASCEntityActions = []

        if let folder = folder, apiClient.active {
            let canEdit = allowEdit(entity: folder)
            let canCopy = allowCopy(entity: folder)
            let canDelete = allowDelete(entity: folder)
            let canShare = allowShare(entity: folder)
            let canDownload = allowDownload(folder: folder)
            let canRename = allowRename(entity: folder)
            let isProjects = folder.rootFolderType == .bunch || folder.rootFolderType == .projects
            let isRoomFolder = isInDocSpaceCategory(folder: folder) && folder.roomType != nil
            let isUserCategory = folder.rootFolderType == .user
            let isArchiveCategory = folder.rootFolderType == .archive
            let isThirdParty = folder.isThirdParty && (folder.parent?.parentId == nil || folder.parent?.parentId == "0")
            let canDuplicateRoom = allowDuplicate(entity: folder) && !folder.isTemplateRoom
            let canCopyLink = isInDocSpaceCategory(folder: folder) && !isArchiveCategory && folder.security.copySharedLink
            let canCreateRoomFromTemplate = allowCreateRoomFrom(template: folder)

            if folder.rootFolderType == .trash {
                return [.delete, .restore]
            }

            let folderIsRoomsListAndNotEmpty: Bool = folder.isRoomListFolder && total > .zero

            if !folder.isEmpty || folderIsRoomsListAndNotEmpty {
                entityActions.insert(.select)
            }

            if canRename, !isRoomFolder {
                entityActions.insert(.rename)
            }

            if canCopy, !isRoomFolder {
                entityActions.insert(.copy)
            }

            if canEdit, canDelete, !isRoomFolder {
                entityActions.insert(.move)
            }

            if canEdit, canShare, !isProjects, !isRoomFolder, !isInDocSpaceCategory(folder: folder) {
                entityActions.insert(.share)
            }

            if canDownload, !folder.isRoot, !folder.isTemplateRoom {
                entityActions.insert(.download)
            }

            if canDelete {
                entityActions.insert(.delete)
            }

            if isThirdParty, !folder.isRoom {
                entityActions.insert(.unmount)
            }

            if folder.new > 0 {
                entityActions.insert(.new)
            }

            if isArchiveCategory, !folder.isRoot {
                entityActions.insert(.link)
                entityActions.insert(.info)
            }

            if canEdit, isDocspace, isUserCategory {
                entityActions.insert(.transformToRoom)
            }

            if isDocspace, folder.isRoom, !(folder.rootFolderType == .archive), !(folder.isTemplateRoom) {
                entityActions.insert(.disableNotifications)
            }

            if isDocspace, folder.isRoom, !(folder.rootFolderType == .archive), !folder.isTemplateRoom, folder.security.editRoom {
                entityActions.insert(.saveAsTemplate)
            }

            if canCreateRoomFromTemplate {
                entityActions.insert(.createRoom)
            }

            if isDocspace, folder.isTemplateRoom, folder.security.editRoom {
                entityActions.insert(.editTemplate)
            }

            if isDocspace, folder.isTemplateRoom, folder.security.delete {
                entityActions.insert(.deleteRoomTemplate)
            }

            if isDocspace, isUserCategory, canShare {
                entityActions.insert(.shareAsRoom)
            }

            if isDocspace, canDuplicateRoom {
                entityActions.insert(.duplicate)
            }

            if canCopyLink {
                entityActions.insert(.link)
            }

            if isRoomFolder, !isArchiveCategory {
                entityActions.insert(.info)
            }

            if isRoomFolder, !isArchiveCategory, !folder.isTemplateRoom {
                entityActions.insert(folder.pinned ? .unpin : .pin)
                if folder.security.editAccess {
                    entityActions.insert(.addUsers)
                    entityActions.insert(.edit)
                }
                if folder.security.move {
                    entityActions.insert(.archive)
                }
                if folder.isCanLeaveRoom {
                    entityActions.insert(.leave)
                }
            }

            if isRoomFolder, isArchiveCategory, folder.security.move {
                entityActions.insert(.unarchive)
            }

            if folder.isRoomListSubfolder,
               folder.parentsFoldersOrCurrentContains(
                   keyPath: \.roomType,
                   value: .virtualData
               ) == true,
               folder.indexing
            {
                entityActions.insert(.editIndex)
                entityActions.insert(.exportRoomIndex)
            }

            if folder.isRoomListSubfolder,
               user?.isAdmin == true,
               !(folder.rootFolderType == .archive),
               !folder.isTemplateRoom
            {
                entityActions.insert(.changeRoomOwner)
            }
        }

        return entityActions
    }

    // MARK: - Action handlers

    func handle(action: ASCEntityActions, folder: ASCFolder, handler: ASCEntityHandler?) {
        switch action {
        case .pin: pinRoom(folder: folder, handler: handler)
        case .unpin: unpinRoom(folder: folder, handler: handler)
        case .archive: archiveRoom(folder: folder, handler: handler)
        case .unarchive: unarchiveRoom(folder: folder, handler: handler)
        case .reorderIndex: reorderIndex(folder: folder, handler: handler)
        case .exportRoomIndex: exportRoomIndex(folder: folder, handler: handler)
        default: unsupportedActionHandler(action: action, handler: handler)
        }
    }

    private func exportRoomIndex(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)
        exportRoomIndex(
            folder: folder,
            process: { progress in
                handler?(.progress, progress, nil)
            }
        ) { result in
            switch result {
            case .success:
                handler?(.end, NSLocalizedString("Success", comment: ""), nil)
            case .failure:
                handler?(
                    .error,
                    nil,
                    ASCProviderError(
                        msg: NSLocalizedString(
                            "Couldn't export room index",
                            comment: ""
                        )
                    )
                )
            }
        }
    }

    private func pinRoom(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)
        apiClient.request(OnlyofficeAPI.Endpoints.Rooms.pin(folder: folder)) { response, error in
            if let folder = response?.result {
                handler?(.end, folder, nil)
            } else {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("You can’t pin more than 10 rooms to the top. Unpin some that are currently pinned.", comment: "")))
            }
        }
    }

    private func unpinRoom(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)
        apiClient.request(OnlyofficeAPI.Endpoints.Rooms.unpin(folder: folder)) { response, error in
            if let folder = response?.result {
                handler?(.end, folder, nil)
            } else {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Unpinned failed.", comment: "")))
            }
        }
    }

    private func archiveRoom(folder: ASCFolder, handler: ASCEntityHandler?) {
        Task { @MainActor in
            handler?(.begin, nil, nil)
            do {
                let id = try await fetchArchiveOperationId(folder: folder)
                for try await progress in progressUpdates(for: id) {
                    handler?(.progress, progress, nil)
                }
                handler?(.end, folder, nil)
            } catch {
                handler?(.error, nil, error)
            }
        }
    }

    private func fetchArchiveOperationId(folder: ASCFolder) async throws -> String {
        guard let archiveOperation = try await OnlyofficeApiClient.request(
            OnlyofficeAPI.Endpoints.Rooms.archive(folder: folder),
            ["deleteAfter": false]
        )?.result else {
            throw NetworkingError.invalidData
        }
        if let errorMessage = archiveOperation.error, !errorMessage.isEmpty {
            throw StringError(errorMessage)
        }
        guard let id = archiveOperation.id else {
            throw NetworkingError.invalidData
        }
        return id
    }

    private func unarchiveRoom(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)
        apiClient.request(OnlyofficeAPI.Endpoints.Rooms.unarchive(folder: folder), ["deleteAfter": true]) { response, error in
            if let folder = response?.result {
                handler?(.end, folder, nil)
            } else {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Unarchiving failed.", comment: "")))
            }
        }
    }

    private func reorderIndex(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)
        apiClient.request(OnlyofficeAPI.Endpoints.Rooms.roomReorder(folder: folder)) { response, error in
            if error == nil, let folder = response?.result {
                handler?(.end, folder, nil)
            } else {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Reorder failed.", comment: "")))
            }
        }
    }

    func checkRoomOwner(folder: ASCFolder) -> Bool {
        return folder.createdBy?.userId == user?.userId
    }

    func leaveRoom(folder: ASCFolder, handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)

        let userId = user?.userId ?? ""
        let access: ASCShareAccess = .none

        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.invitations = [.init(id: userId, access: access)]

        apiClient.request(OnlyofficeAPI.Endpoints.Sharing.inviteRequest(folder: folder), inviteRequestModel.toJSON()) {
            result, error in
            if error != nil {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Couldn't change the room owner", comment: "")))
            } else {
                handler?(.end, folder, nil)
            }
        }
    }

    // Download
    func download(
        items: [ASCEntity],
        process: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        var folderIds: [String] = []
        var fileIds: [String] = []
        var itemName: String = ""

        for entity in items {
            if let folder = entity as? ASCFolder {
                folderIds.append(folder.id)
                itemName = folder.title
            } else if let file = entity as? ASCFile {
                fileIds.append(file.id)
                itemName = file.parent?.title ?? file.title
            }
        }

        let files: [String: Any] = [
            "fileIds": fileIds,
            "folderIds": folderIds,
        ]

        let prepareArchiveError = ASCProviderError(msg: NSLocalizedString("Failure to prepare the archive", comment: ""))

        // API request for file formation
        apiClient.request(OnlyofficeAPI.Endpoints.Operations.download, files) { [weak self] result, error in
            guard let self else { return }

            if let error {
                completion(.failure(error))
                return
            }

            if let operation = result?.result?.first {
                self.checkOperation(operation: operation) { progress in
                    let commonProgress = self.progress(progress, in: 0 ... 0.3)
                    process(commonProgress)
                } completion: { result in
                    switch result {
                    case let .success(url):
                        guard let url else {
                            completion(.failure(prepareArchiveError))
                            return
                        }

                        // Download prepared archive
                        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(itemName).zip")
                        self.download(url.absoluteString, to: destinationURL) { data, progress, error in
                            let commonProgress = self.progress(Float(progress), in: 0.3 ... 1)
                            process(commonProgress)

                            if let error {
                                completion(.failure(error))
                                return
                            }

                            if progress >= 1 {
                                completion(.success(destinationURL))
                            }
                        }

                    case let .failure(error):
                        log.error(error)
                        completion(.failure(prepareArchiveError))
                    }
                }
            } else {
                completion(.failure(prepareArchiveError))
            }
        }
    }

    func exportRoomIndex(
        folder: ASCFolder,
        process: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let prepareExportError = ASCProviderError(msg: NSLocalizedString("Failed to prepare the index export", comment: ""))

        apiClient.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.roomIndexExport(folder: folder)
        ) { [weak self] result, error in
            guard let self else { return }

            if let error {
                completion(.failure(error))
                return
            }

            if let operation = result?.result {
                self.fetchAndProcessOperation(
                    operation: operation,
                    endpoint: OnlyofficeAPI.Endpoints.Operations.roomIndexExport,
                    timeInterval: 1
                ) { progress in
                    let commonProgress = self.progress(progress, in: 0 ... 0.3)
                    process(commonProgress)
                } completion: { result in
                    switch result {
                    case let .success(model):
                        guard let url = URL(string: model?.resultFileUrl ?? "") else {
                            completion(.failure(prepareExportError))
                            return
                        }

                        let fileName = model?.resultFileName ?? ""
                        let message = "\(fileName) \(NSLocalizedString("file exported to Documents", comment: ""))"

                        let alertController = UIAlertController.alert(
                            "",
                            message: message,
                            actions: []
                        )
                        .action(title: NSLocalizedString("Open file", comment: "")) { [weak self] _ in
                            guard let self else { return }
                            let file = ASCFile()
                            file.id = String(model?.resultFileId ?? .zero)
                            self.apiClient.request(endpoint: OnlyofficeAPI.Endpoints.Files.info(file: file)) { result, error in
                                if let file = result?.result {
                                    self.open(
                                        file: file,
                                        openMode: .edit,
                                        canEdit: true
                                    )
                                }
                            }
                        }
                        .cancelable()

                        if let topVC = ASCViewControllerManager.shared.topViewController {
                            topVC.present(alertController, animated: true, completion: nil)
                        }

                        completion(.success(url))

                    case let .failure(error):
                        log.error(error)
                        completion(.failure(prepareExportError))
                    }
                }
            } else {
                completion(.failure(prepareExportError))
            }
        }
    }

    private func checkOperation(
        operation: OnlyofficeFileOperation,
        timeInterval: TimeInterval = 0.5,
        process: @escaping (Float) -> Void,
        completion: @escaping (Result<URL?, Error>) -> Void
    ) {
        var doCheckOperation: (() -> Void)?
        var preventCheck = false

        doCheckOperation = { [weak self] in
            self?.apiClient.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                guard !preventCheck else { return }

                if let error {
                    preventCheck = true
                    completion(.failure(error))
                    return
                }

                if let operation = result?.result?.first(where: { $0.id == operation.id }),
                   let progress = operation.progress
                {
                    process(Float(progress) / 100.0)

                    if let operationError = operation.error, !operationError.isEmpty {
                        completion(.failure(ASCProviderError(msg: operationError)))
                        return
                    }

                    if operation.finished {
                        completion(.success(URL(string: operation.url ?? "")))
                        return
                    }

                    DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                        doCheckOperation?()
                    }
                }
            }
        }

        doCheckOperation?()
    }

    private func fetchAndProcessOperation<T: OnlyofficeOperation>(
        operation: T,
        endpoint: Endpoint<OnlyofficeResponse<T>>,
        timeInterval: TimeInterval,
        process: @escaping (Float) -> Void,
        completion: @escaping (Result<T?, Error>) -> Void
    ) {
        var doCheckOperation: (() -> Void)?
        var preventCheck = false

        doCheckOperation = { [weak self] in
            self?.apiClient.request(endpoint) { result, error in
                guard !preventCheck else { return }

                if let error {
                    preventCheck = true
                    completion(.failure(error))
                    return
                }

                if let updatedOperation = result?.result,
                   updatedOperation.id == operation.id,
                   let progress = updatedOperation.percentage
                {
                    process(Float(progress) / 100.0)

                    if let operationError = updatedOperation.error, !operationError.isEmpty {
                        preventCheck = true
                        completion(.failure(ASCProviderError(msg: operationError)))
                        return
                    }

                    if updatedOperation.isCompleted {
                        preventCheck = true
                        completion(.success(updatedOperation))
                        return
                    }

                    DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                        doCheckOperation?()
                    }
                }
            }
        }

        doCheckOperation?()
    }

    private func progress(_ progress: Float, in range: ClosedRange<Float> = 0 ... 1) -> Float {
        range.lowerBound + (range.upperBound - range.lowerBound) * progress
    }

    private func unsupportedActionHandler(action: ASCEntityActions, handler: ASCEntityHandler?) {
        log.error("Unsupported action \(action.rawValue)")
        handler?(.error, nil, ASCProviderError(msg: "Unsupported action"))
    }

    private func updateItem(_ item: ASCEntity) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            delegate?.updateItems(at: [index])
        }
    }

    // MARK: - Helpers

    func absoluteUrl(from string: String?) -> URL? {
        return apiClient.absoluteUrl(from: URL(string: string ?? ""))
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
        // Internal reset session, do not handle
        if let error = error as? NetworkingError {
            switch error {
            case .cancelled, .sessionDeinitialized:
                return true
            default:
                break
            }
        }

        let endSessionLife = apiClient.expires == nil || Date() > apiClient.expires!

        var alertTitle = ASCLocalization.Error.unknownTitle
        var alertMessage = String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), apiClient.baseURL?.absoluteString ?? "")

        if endSessionLife {
            alertTitle = NSLocalizedString("Your session has expired", comment: "")
            alertMessage = NSLocalizedString("Please re-login to renew your session.", comment: "")
            errorFeedback(title: alertTitle, message: alertMessage)
        } else if let error = error as? NetworkingError {
            switch error {
            case let .apiError(error):
                if let error = error as? OnlyofficeServerError {
                    switch error {
                    case .paymentRequired:
                        return true
                    case .unauthorized:
                        errorFeedback(title: error.localizedDescription, message: NSLocalizedString("Please re-login to renew your session.", comment: ""))
                    case let .unknown(message):
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
            case let .apiError(error):
                if let onlyofficeError = error as? OnlyofficeServerError {
                    switch onlyofficeError {
                    case .paymentRequired:
                        return
                    case .forbidden:
                        title = ASCLocalization.Error.forbiddenTitle
                        message = ASCLocalization.Error.forbiddenMsg
                    default:
                        message = error.localizedDescription
                    }
                }

            case .cancelled, .sessionDeinitialized:
                return

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
                }
            )
        )

        if allowRenew {
            alertError.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Renewal", comment: ""),
                    style: .cancel,
                    handler: { [weak self] action in
                        let currentAccout = ASCAccountsManager.shared.get(by: self?.apiClient.baseURL?.absoluteString ?? "", email: self?.user?.email ?? "")
                        ASCUserProfileViewController.logout(renewAccount: currentAccout)
                    }
                )
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

    func open(file: ASCFile, openMode: ASCDocumentOpenMode, canEdit: Bool) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let allowOpen = ASCConstants.FileExtensions.allowEdit.contains(fileExt) || file.editable

        guard allowOpen else { return }

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
        let fillFormDidSendHandler: ASCEditorManagerFillFormDidSendHandler = { file, fillingSessionId, complation in
            guard let file else { complation(false); return }

            // Update file info
            self.apiClient.request(OnlyofficeAPI.Endpoints.Files.info(file: file)) { [weak self] response, error in
                if let self, let file = response?.result {
                    self.updateItem(file)
                }
            }

            guard let fillingSessionId else { complation(false); return }

            self.fillFormDidSubmit(file, fillingSessionId: fillingSessionId) { provider, result, success, error in
                complation(success)
            }
        }

        let isShareFile = file.requestToken != nil
        let copyProvider = copy() as! ASCOnlyofficeProvider
        copyProvider.cancel()
        copyProvider.reset()
        copyProvider.folder = folder
        if isShareFile {
            let editorManager = ASCEditorManager(config: ASCEditorManager.Configuration(onlyofficeClient: apiClient))
            editorManager.editCloud(
                file,
                provider: copyProvider,
                openMode: openMode,
                canEdit: canEdit,
                openHandler: openHandler,
                closeHandler: closeHandler,
                favoriteHandler: favoriteHandler,
                shareHandler: shareHandler,
                renameHandler: renameHandler,
                fillFormDidSendHandler: fillFormDidSendHandler
            )
        } else if ASCEditorManager.shared.checkSDKVersion() {
            ASCEditorManager.shared.editCloud(
                file,
                provider: copyProvider,
                openMode: openMode,
                canEdit: canEdit,
                openHandler: openHandler,
                closeHandler: closeHandler,
                favoriteHandler: favoriteHandler,
                shareHandler: shareHandler,
                renameHandler: renameHandler,
                fillFormDidSendHandler: fillFormDidSendHandler
            )
        } else {
            ASCEditorManager.shared.editFileLocally(
                for: self,
                file,
                openMode: openMode,
                canEdit: canEdit,
                handler: openHandler,
                closeHandler: closeHandler,
                renameHandler: renameHandler,
                lockedHandler: {
                    delay(seconds: 0.3) {
                        let isSpreadsheet = file.title.fileExtension() == ASCConstants.FileExtensions.xlsx
                        let isPresentation = file.title.fileExtension() == ASCConstants.FileExtensions.pptx

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
                            actions: []
                        )
                        .okable { _ in
                            let openHandler = strongDelegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0)
                            let closeHandler = strongDelegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))

                            ASCEditorManager.shared.editFileLocally(
                                for: self,
                                file,
                                openMode: openMode,
                                canEdit: false,
                                handler: openHandler,
                                closeHandler: closeHandler
                            )
                        }
                        .cancelable()

                        if let topVC = ASCViewControllerManager.shared.topViewController {
                            topVC.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            )
        }
    }

    func preview(file: ASCFile, openMode: ASCDocumentOpenMode = .view, files: [ASCFile]?, in view: UIView?) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isPdf = fileExt == ASCConstants.FileExtensions.pdf
        let isImage = ASCConstants.FileExtensions.images.contains(fileExt)
        let isVideo = ASCConstants.FileExtensions.videos.contains(fileExt)
        let isAllowConvert =
            ASCConstants.FileExtensions.documents.contains(fileExt) ||
            ASCConstants.FileExtensions.spreadsheets.contains(fileExt) ||
            ASCConstants.FileExtensions.presentations.contains(fileExt)

        lazy var openHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...", 0.15)
        lazy var openPdfHandler = delegate?.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0.15)
        lazy var closeHandler = delegate?.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))
        lazy var renameHandler: ASCEditorManagerRenameHandler = { file, title, complation in
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
            ASCEditorManager.shared.browsePdfCloud(
                for: self,
                file,
                openMode: openMode,
                openHandler: openPdfHandler,
                closeHandler: closeHandler,
                renameHandler: renameHandler
            )
        } else if isImage || isVideo {
            ASCEditorManager.shared.browseMedia(for: self, file, files: files)
        } else if isAllowConvert {
            // TODO: !!! Convert me
        } else {
            if let view {
                ASCEditorManager.shared.browseUnknownCloud(for: self, file, inView: view, handler: openHandler)
            }
        }
    }

    func segmentCategory(of folder: ASCFolder) -> [ASCSegmentCategory] {
        guard
            let docspaceVersion = apiClient.serverVersion?.docSpace,
            docspaceVersion.isVersion(greaterThanOrEqualTo: "2.5.1"),
            docspaceVersion.isVersion(lessThan: "3.5.0")
        else { return [] }

        if folder.isRoot, folder.rootFolderType == .user {
            let resentFolder = folder.copy()
            resentFolder.rootFolderType = .recent
            resentFolder.id = OnlyofficeAPI.Path.Folder.recentRaw

            return [
                ASCSegmentCategory(title: NSLocalizedString("My Documents", comment: ""), folder: folder),
                ASCSegmentCategory(title: NSLocalizedString("Recently accessible via link", comment: ""), folder: resentFolder),
            ]
        }

        guard
            let docspaceVersion = apiClient.serverVersion?.docSpace,
            docspaceVersion.isVersion(greaterThanOrEqualTo: "3.1.0")
        else { return [] }

        if folder.isRoot, folder.rootFolderType == .virtualRooms {
            let roomTemplates = folder.copy()
            roomTemplates.rootFolderType = .roomTemplates
            roomTemplates.id = OnlyofficeAPI.Path.Folder.room

            return [
                ASCSegmentCategory(title: NSLocalizedString("Rooms", comment: ""), folder: folder),
                ASCSegmentCategory(title: NSLocalizedString("Templates", comment: ""), folder: roomTemplates),
            ]
        }

        return []
    }
}

extension ASCOnlyofficeProvider {
    func generalFileLink(file: ASCFile) async throws -> String {
        guard file.rootFolderType == .virtualRooms,
              let baseUrl = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString
        else {
            return try await sharedService.createAndCopy(
                file: file,
                requestModel: CreateAndCopyLinkRequestModel(
                    access: ASCShareAccess.read.rawValue,
                    expirationDate: nil,
                    isInternal: false
                )
            ).sharedTo.shareLink
        }

        let path = "%@/doceditor?fileId=%@"
        let urlStr = String(format: path, baseUrl, file.id)
        return urlStr
    }

    func generalLink(forFolder folder: ASCFolder) async -> Result<String, Error> {
        if folder.isRoom {
            let result = await generalLink(forRoom: folder)
            return result
        }

        if folder.isRoomListSubfolder, let link = generalLink(forRoomSubfolder: folder) {
            return .success(link)
        }

        return .failure(NetworkingError.invalidUrl)
    }

    private func generalLink(forRoom room: ASCFolder) async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            guard room.roomType != .colobaration && room.roomType != .virtualData && room.rootFolderType != .roomTemplates else {
                if let baseUrl = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString {
                    let path = "%@/rooms/shared/filter?folder=%@"
                    let urlStr = String(format: path, baseUrl, room.id)
                    continuation.resume(returning: .success(urlStr))
                } else {
                    continuation.resume(returning: .failure(NetworkingError.invalidUrl))
                }
                return
            }

            apiClient.request(OnlyofficeAPI.Endpoints.Rooms.getLink(folder: room)) { response, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                    return
                }

                var urlComponets = URLComponents(string: self.apiClient.baseURL?.absoluteString ?? "")
                urlComponets?.path = "/\(OnlyofficeAPI.Path.defaultGeneralLink)"
                urlComponets?.queryItems = [
                    URLQueryItem(name: "folder", value: room.id),
                ]

                var generalLink = urlComponets?.url?.absoluteString ?? ""

                if let linkInfo = response?.result {
                    generalLink = linkInfo.linkInfo.shareLink
                }

                continuation.resume(
                    returning: .success(generalLink)
                )
            }
        }
    }

    private func generalLink(forRoomSubfolder folder: ASCFolder) -> String? {
        guard folder.isRoomListSubfolder,
              let baseUrl = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString
        else { return nil }
        let path = "%@/rooms/shared/%@/filter?folder=%@"
        let urlStr = String(format: path, baseUrl, folder.id, folder.id)
        return urlStr
    }

    private func progressUpdates(for operationId: String, interval: UInt64 = NSEC_PER_SEC) -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var progress = try await fetchOperationProgress(operationId: operationId)
                    while progress < 100 && !Task.isCancelled {
                        continuation.yield(progress)
                        try await Task.sleep(nanoseconds: interval)
                        progress = try await fetchOperationProgress(operationId: operationId)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func fetchOperationProgress(operationId: String) async throws -> Int {
        guard let resultOperation = try await OnlyofficeApiClient.request(
            OnlyofficeAPI.Endpoints.Operations.list(urlEncoding: .default),
            ["id": operationId]
        )?.result?.first else {
            throw NetworkingError.invalidData
        }
        if let errorMessage = resultOperation.error, !errorMessage.isEmpty {
            throw StringError(errorMessage)
        }
        guard let progress = resultOperation.progress else {
            throw NetworkingError.invalidData
        }
        return progress
    }
}

private extension ASCOnlyofficeProvider {
    enum FilterControllerType: Equatable {
        case documents
        case docspaceRooms
        case docspace
    }
}

private extension ASCFiltersControllerProtocol {
    var type: ASCOnlyofficeProvider.FilterControllerType {
        if self is ASCOnlyOfficeFiltersController {
            return .documents
        } else if self is ASCDocSpaceRoomsFiltersController {
            return .docspaceRooms
        } else if self is ASCDocSpaceFiltersController {
            return .docspace
        }
        return .documents
    }
}

extension ASCOnlyofficeProvider {
    var isDocspace: Bool {
        apiClient.serverVersion?.docSpace != nil
    }

    static var isDocspaceApi: Bool {
        ASCFileManager.onlyofficeProvider?.apiClient.serverVersion?.docSpace != nil
    }
}

// MARK: ASCEntityViewLayoutTypeProvider

extension ASCOnlyofficeProvider {
    var itemsViewType: ASCEntityViewLayoutType {
        get {
            itemsViewType(for: folder)
        }
        set {
            ASCEntityViewLayoutTypeService.shared.itemsViewType = newValue
        }
    }

    func itemsViewType(for folder: ASCFolder?) -> ASCEntityViewLayoutType {
        if let folder, folder.parentsFoldersOrCurrentContains(
            keyPath: \.indexing,
            value: true
        ) {
            return .list
        }
        return ASCEntityViewLayoutTypeService.shared.itemsViewType
    }
}

extension ASCOnlyofficeProvider: TopBannerViewModelDelegate {
    func topBannerViewModel(for folder: ASCFolder?) -> TopBannerViewModel? {
        if let formattedString = folder?.lifetime?.formattedLifetimeString() {
            return .lifetime(formattedString: formattedString)
        } else if folder?.rootFolderType == .trash {
            return .trash
        }
        return nil
    }
}

extension ASCOnlyofficeProvider: ProviderEditIndexDelegate {
    func changeOrderIndex(for entity: ASCEntity, toIndex index: Int) {
        guard let srcItemIndex = items.firstIndex(where: { $0.id == entity.id }) else {
            return
        }
        if itemsBeforeEditingOrder.isEmpty {
            itemsBeforeEditingOrder = items
        }
        let srcItem = items[srcItemIndex]
        let newSrcItemIndex = items[index].orderIndex

        // If moving up in the array (shift down items between index and srcItemIndex
        if srcItemIndex > index {
            for i in index ..< srcItemIndex {
                items[i].orderIndex = items[i + 1].orderIndex
                itemsIdsWithChangedOrderIndex.insert(items[i].id)
            }
        }
        // If moving down in the array (shift up items between srcItemIndex and index)
        else if srcItemIndex < index {
            var prevValue = srcItem.orderIndex
            for i in srcItemIndex ... index {
                let bufferValue = items[i].orderIndex
                items[i].orderIndex = prevValue
                prevValue = bufferValue
                itemsIdsWithChangedOrderIndex.insert(items[i].id)
            }
        }

        // Remove the item from the current position and insert it at the new position
        items.remove(at: srcItemIndex)
        items.insert(srcItem, at: index)
        srcItem.orderIndex = newSrcItemIndex
        itemsIdsWithChangedOrderIndex.insert(srcItem.id)
    }

    func cancleEditOrderIndex() {
        if !itemsBeforeEditingOrder.isEmpty {
            items = itemsBeforeEditingOrder
            let itemsOrders = itemsBeforeEditingOrder
                .sorted(by: { $0.orderIndex ?? "" < $1.orderIndex ?? "" })
                .map { $0.orderIndex }
            for (index, item) in items.enumerated() {
                item.orderIndex = itemsOrders[index]
            }
            itemsBeforeEditingOrder = []
        }
        itemsIdsWithChangedOrderIndex.removeAll()
    }

    func applyEditedOrderIndex(completion: @escaping (ErrorMessage?) -> Void) {
        let requestModel = itemsIdsWithChangedOrderIndex
            .compactMap { id in items.first(where: { $0.id == id }) }
            .filesOrderRequestModel
        apiClient.request(OnlyofficeAPI.Endpoints.Files.order, requestModel.dictionary) { result, error in
            DispatchQueue.main.async {
                completion(error?.localizedDescription)
            }
        }

        itemsBeforeEditingOrder = []
        itemsIdsWithChangedOrderIndex.removeAll()
    }
}

private extension OnlyofficeApiClient {
    func savePasswordCookiesToHeaders(endpoint: Endpoint<OnlyofficeResponseCodable<SharePasswordResponseModel>>) {
        guard let url = url(path: endpoint.path) else { return }
        let service = ServicesProvider.shared.onlyofficeHeadersOnTokenService
        HTTPCookieStorage.shared.cookies(for: url)?
            .filter { $0.name.contains(String.passwordCookiePrefix) }
            .map { HTTPHeader(name: $0.name, value: $0.value) }
            .forEach { service.add(header: $0, for: self.token ?? "") }
    }
}

private extension String {
    static let passwordCookiePrefix = "sharelink"
}

struct StringError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}

extension StringError: Equatable {}

enum ASCOnlyofficeProviderError: Error {
    case couldntGetAccess
}
