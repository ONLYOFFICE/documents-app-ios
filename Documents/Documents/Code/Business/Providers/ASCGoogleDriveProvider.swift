//
//  ASCGoogleDriveProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.10.2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import FileKit
import Firebase

class ASCGoogleDriveProvider: ASCFileProviderProtocol & ASCSortableFileProviderProtocol {

    // MARK: - Properties

    var id: String? {
        get {
            if let user = googleUser {
                return user.userID
            }
            return nil
        }
    }
    var type: ASCFileProviderType {
        get {
            return .googledrive
        }
    }
    var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString(NSLocalizedString("My Drive", comment: ""), comment: "")
                $0.rootFolderType = .googledriveAll
                $0.id = "root"
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
                let googleUser = googleUser,
                let token = googleUser.authentication.accessToken
            else { return nil }

            return "Bearer \(token)"
        }
    }
    var delegate: ASCProviderDelegate?

    internal var folder: ASCFolder?
    internal var fetchInfo: [String : Any?]?

    private let googleDriveService = GTLRDriveService()
    private var googleUser: GIDGoogleUser?
    private var fetcher = GTMSessionFetcher()
    
    struct ApiPath {
        static let contentLinkById = "https://www.googleapis.com/download/drive/v3/files/%@?alt=media"
    }

    enum ErrorType: String {
        case providerUndefined = "ASCGoogleDriveProviderProviderUndefined"
        case userUndefined = "ASCGoogleDriveProviderUserUndefined"
        case readFolder = "ASCGoogleDriveProviderReadFolder"
        case download = "ASCGoogleDriveProviderDownload"
        case upload = "ASCGoogleDriveProviderUpload"
        
        var description: String {
            switch self {
            case .providerUndefined: return NSLocalizedString("Unknown file provider", comment: "")
            case .userUndefined: return NSLocalizedString("User undefined", comment: "")
            case .readFolder: return NSLocalizedString("Failed to get file list.", comment: "")
            case .download: return  NSLocalizedString("Сould not download file.", comment: "")
            case .upload: return  NSLocalizedString("Сould not upload file.", comment: "")
            }
        }
    }
    
    private let googleMimeTypes = [
        "application/vnd.google-apps.document",
        "application/vnd.google-apps.spreadsheet",
        "application/vnd.google-apps.presentation",
        "application/vnd.google-apps.form"
    ]
    private let defaultObjectFields = "id,name,mimeType,modifiedTime,createdTime,fileExtension,size,webContentLink,parents"

    // MARK: - Lifecycle Methods
    
    init() {
        //
    }
    
    init(userData: Data) {
        /// https://medium.com/@kgleong/uploading-files-to-google-drive-using-the-google-ios-sdk-fcad3e9d6c07
        /// https://github.com/google/google-api-objectivec-client-for-rest/blob/master/Examples/DriveSample/DriveSampleWindowController.m
        /// https://developers.google.com/drive/api/v3/about-files
        /// https://github.com/net3ton/moneytravel/blob/b11955b44183bea1ec3dbe1c343cf87952774872/moneytravel/GoogleDrive.swift
        /// https://github.com/wtanuw/WTLibrary-iOS/blob/efe49d5561f7e317963cae8d7d12054fe0af8871/WTLibrary-iOS/Classes/WTGoogle/WTGoogleDriveManager.m

// Test archive->unarchive
//        do {
//            googleUser = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(userData) as? GIDGoogleUser
//            googleDriveService.authorizer = googleUser?.authentication.fetcherAuthorizer()
//        } catch {
//            log.error("Failed to create ASCGoogleDriveProvider")
//        }
        
// Test serialize data->string->data
//        let data2string = userData.base64EncodedString(options: NSData.Base64EncodingOptions())
//        let string2data = Data(base64Encoded: data2string, options: NSData.Base64DecodingOptions())


        googleUser = NSKeyedUnarchiver.unarchiveObject(with: userData) as? GIDGoogleUser
        googleDriveService.authorizer = googleUser?.authentication.fetcherAuthorizer()
    }

    func copy() -> ASCFileProviderProtocol {
        let copy = ASCGoogleDriveProvider()
        
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
        if fetcher.isFetching {
            fetcher.stopFetching()
        }
    }

    func serialize() -> String? {
        var info: [String: Any] = [
            "type": type.rawValue
        ]
        
        if  let user = googleUser {
            let userData = NSKeyedArchiver.archivedData(withRootObject: user)
            let userString = userData.base64EncodedString(options: NSData.Base64EncodingOptions())

            info += ["googleuser": userString]
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
            if let userString = json["googleuser"] as? String,
               let userData = Data(base64Encoded: userString, options: NSData.Base64DecodingOptions())
            {
                googleUser = NSKeyedUnarchiver.unarchiveObject(with: userData) as? GIDGoogleUser
                googleDriveService.authorizer = googleUser?.authentication.fetcherAuthorizer()
            }
            
            if let userJson = json["user"] as? [String: Any] {
                user = ASCUser(JSON: userJson)
            }
        }
    }
    
    func add(item: ASCEntity, at index: Int) {
        items.insert(item, at: index)
        total += 1
    }
    
    func add(items: [ASCEntity], at index: Int) {
        self.items.insert(contentsOf: items, at: index)
        self.total += items.count
    }
    
    func remove(at index: Int) {
        items.remove(at: index)
        total -= 1
    }
    
    func isReachable(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        DispatchQueue.main.async(execute: { [weak self] in
            self?.userInfo { success, error in
                completionHandler(success, error)
            }
        })
    }
    
    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    func userInfo(completeon: ASCProviderUserInfoHandler?) {
        guard let googleUser = googleUser else {
            let error = ASCProviderError(msg: ErrorType.userUndefined.description)
            completeon?(false, error)
            return
        }
        
        user = ASCUser()
        user?.userId = googleUser.userID
        user?.displayName = googleUser.profile.name
        user?.department = googleUser.profile.email
        
        completeon?(true, nil)
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

    /// Fetch an Array of 'ASCEntity's identifying the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    func fetch(for folder: ASCFolder, parameters: [String : Any?], completeon: ASCProviderCompletionHandler?) {
        guard let googleUser = googleUser else {
            completeon?(self, folder, false, nil)
            return
        }
        
        self.folder = folder
        
        let fetch: ((_ completeon: ASCProviderCompletionHandler?) -> Void) = { [weak self] completeon in
            guard let strongSelf = self else { return }
            
            let query = GTLRDriveQuery_FilesList.query()
            
            // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
            query.spaces = "drive"
            
            // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
            query.corpora = "user"
            
            var queryParams = ""
            
            queryParams += "'\(folder.id)' in parents and trashed = false"
            
            // Only owned items
            queryParams += " and '\(googleUser.profile!.email!)' in owners"
            
            // Search
            if
                let search = parameters["search"] as? [String: Any],
                let text = (search["text"] as? String)?.trim(),
                text.length > 0
            {
                queryParams += " and name contains '\(text.lowercased())'"
            }
            
            query.q = queryParams
            query.fields = "files(id,name,mimeType,modifiedTime,createdTime,fileExtension,size,webContentLink)"
            
            strongSelf.googleDriveService.executeQuery(query) { _, result, error in
                DispatchQueue.main.async(execute: {
                    if let error = error {
                        completeon?(strongSelf, folder, false, error)
                        return
                    }
                    
                    guard
                        let collection = result as? GTLRDrive_FileList,
                        let objects = collection.files
                    else {
                        completeon?(strongSelf, folder, false, ASCProviderError(msg: ErrorType.readFolder.description))
                        return
                    }
                    
                    var files: [ASCFile] = []
                    var folders: [ASCFolder] = []
                    
                    folders = objects
                        .filter { $0.mimeType == "application/vnd.google-apps.folder" }
                        .map {
                            let cloudFolder = ASCFolder()
                            cloudFolder.id = $0.identifier ?? ""
                            cloudFolder.rootFolderType = .googledriveAll
                            cloudFolder.title = $0.name ?? ""
                            cloudFolder.created = $0.createdTime?.date
                            cloudFolder.updated = $0.modifiedTime?.date
                            cloudFolder.createdBy = strongSelf.user
                            cloudFolder.updatedBy = strongSelf.user
                            cloudFolder.parent = folder
                            cloudFolder.parentId = folder.id
                            
                            return cloudFolder
                    }
                    
                    files = objects
                        .filter { $0.mimeType != "application/vnd.google-apps.folder" }
                        .map {
                            let fileSize: UInt64 = max(0, UInt64(truncating: $0.size ?? 0))
                            let cloudFile = ASCFile()
                            cloudFile.id = $0.identifier ?? ""
                            cloudFile.rootFolderType = .googledriveAll
                            cloudFile.title = $0.name ?? ""
                            cloudFile.created = $0.createdTime?.date
                            cloudFile.updated = $0.modifiedTime?.date
                            cloudFile.createdBy = strongSelf.user
                            cloudFile.updatedBy = strongSelf.user
                            cloudFile.parent = folder
                            cloudFile.viewUrl = $0.identifier ?? ""
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
    
    /// Fetch an direct URL to the content
    ///
    /// - Parameters:
    ///   - string: content path
    func absoluteUrl(from string: String?) -> URL? {
        let urlString = String(format: ASCGoogleDriveProvider.ApiPath.contentLinkById, string ?? "")
        return URL(string: urlString)
    }
    
    /// Download an file on path via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - path: file path or id
    ///   - destinationURL: url of destination
    ///   - processing: a closure with result of operation or error
    func download(_ path: String, to destinationURL: URL, processing: @escaping ASCApiProgressHandler) {
        guard let _ = googleUser else {
            processing(0, nil, ASCProviderError(msg: ErrorType.download.description), nil)
            return
        }

        // Force stop fetching
        cancel()
        
        // Query metadata file info
        let queryMetadata = GTLRDriveQuery_FilesGet.query(withFileId: path)
        queryMetadata.fields = "id,name,mimeType,size"
        
        googleDriveService.executeQuery(queryMetadata) { [weak self] _, result, error in
            DispatchQueue.main.async(execute: { [weak self] in
                if let _ = error {
                    processing(0, nil, ASCProviderError(msg: ErrorType.download.description), nil)
                    return
                }

                guard
                    let strongSelf = self,
                    let googleFileInfo = result as? GTLRDrive_File
                else {
                    processing(0, nil, ASCProviderError(msg: ErrorType.download.description), nil)
                    return
                }

                var queryDownload: GTLRDriveQuery
                
                // Googles own format can be downloaded via this query
                // https://developers.google.com/drive/v3/web/manage-downloads
                if strongSelf.googleMimeTypes.contains(googleFileInfo.mimeType ?? "") {
                    queryDownload = GTLRDriveQuery_FilesExport.queryForMedia(withFileId: path, mimeType: "application/pdf")
                } else {
                    queryDownload = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: path)
                }
                
                let downloadRequest = strongSelf.googleDriveService.request(for: queryDownload) as URLRequest

                strongSelf.fetcher = strongSelf.googleDriveService.fetcherService.fetcher(with: downloadRequest)

                // Progress
                strongSelf.fetcher.downloadProgressBlock = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    let expectedSize = max(1, googleFileInfo.size?.uint64Value ?? 0)
                    let progress = Double(totalBytesWritten) / Double(expectedSize)
                    
                    DispatchQueue.main.async {
                        processing(progress, nil, nil, nil)
                    }
                }
                
                // Prepare destination
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } catch {
                    log.error(error)
                    processing(1.0, nil, error, nil)
                    return
                }
                
                // Do fetch
                strongSelf.fetcher.destinationFileURL = destinationURL
                strongSelf.fetcher.beginFetch(completionHandler: { data, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            processing(1.0, nil, error, nil)
                        } else {
                            processing(1.0, destinationURL, nil, nil)
                        }
                    }
                })
            })
        }
    }
    
    /// Upload data on path via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - path: file path or id
    ///   - data: upload data
    ///   - params: additional params
    ///   - processing: a closure with result of operation or error
    func modify(_ path: String, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        guard let _ = googleUser else {
            processing(0, nil, ASCProviderError(msg: ErrorType.upload.description), nil)
            return
        }

        // Force stop fetching
        cancel()
        
        // Query metadata file info
        let metadataFields = defaultObjectFields
        let queryMetadata = GTLRDriveQuery_FilesGet.query(withFileId: path)
        queryMetadata.fields = "id,name,mimeType,size,parents"
        
        googleDriveService.executeQuery(queryMetadata) { [weak self] _, result, error in
            DispatchQueue.main.async(execute: { [weak self] in
                if let _ = error {
                    processing(0, nil, ASCProviderError(msg: ErrorType.upload.description), nil)
                    return
                }

                guard
                    let strongSelf = self,
                    let googleFileInfo = result as? GTLRDrive_File,
                    let mimeType = googleFileInfo.mimeType
                else {
                    processing(0, nil, ASCProviderError(msg: ErrorType.upload.description), nil)
                    return
                }
                
                let metadata = GTLRDrive_File()
                metadata.name = googleFileInfo.name ?? ""
                metadata.parents = googleFileInfo.parents ?? []
                
                // Remove original
                let queryDelete = GTLRDriveQuery_FilesDelete.query(withFileId: path)
                strongSelf.googleDriveService.executeQuery(queryDelete) { ticket, file, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            processing(1.0, nil, error, nil)
                            return
                        }
                        
                        // Upload changes
                        let uploadParameters = GTLRUploadParameters(data: data, mimeType: mimeType)
                        let queryCreate = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
                        queryMetadata.fields = metadataFields
                        
                        let ticket = strongSelf.googleDriveService.executeQuery(queryCreate) { ticket, file, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    processing(1.0, nil, error, nil)
                                } else if let fileObject = file as? GTLRDrive_File {
                                    let fileSize: UInt64 = max(0, UInt64(truncating: fileObject.size ?? 0))
                                    
                                    let parent = ASCFolder()
                                    parent.id = fileObject.parents?.first ?? ""
                                    
                                    let cloudFile = ASCFile()
                                    cloudFile.id = fileObject.identifier ?? ""
                                    cloudFile.rootFolderType = .googledriveAll
                                    cloudFile.title = fileObject.name ?? ""
                                    cloudFile.created = fileObject.createdTime?.date
                                    cloudFile.updated = fileObject.modifiedTime?.date
                                    cloudFile.createdBy = strongSelf.user
                                    cloudFile.updatedBy = strongSelf.user
                                    cloudFile.parent = parent
                                    cloudFile.viewUrl = fileObject.identifier ?? ""
                                    cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                                    cloudFile.pureContentLength = Int(fileSize)
                                    
                                    processing(1.0, cloudFile, nil, nil)
                                } else {
                                    processing(1.0, nil, nil, nil)
                                }
                            }
                        }
                        ticket.objectFetcher?.sendProgressBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
                            DispatchQueue.main.async {
                                log.debug("progress: \(Double(totalBytesSent) / Double(max(1, totalBytesExpectedToSend)))")
                                processing(Double(totalBytesSent) / Double(max(1, totalBytesExpectedToSend)), nil, nil, nil)
                            }
                        }
                    }
                }
            })
        }
    }

    /// Upload data on path via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - path: parent folder id
    ///   - data: upload data
    ///   - params: additional params
    ///   - processing: a closure with result of operation or error
    func upload(_ path: String, data: Data, overwrite: Bool, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        guard
            let _ = googleUser,
            let fileName = params?["title"] as? String
            else {
                processing(0, nil, ASCProviderError(msg: ErrorType.upload.description), nil)
                return
        }
        
        // Force stop fetching
        cancel()
        
        let mimeType = params?["mime"] as? String ?? "application/octet-stream"
        
        if overwrite, let fileId = params?["fileId"] as? String {
            let deleteFile: ASCFile = {
                $0.id = fileId
                return $0
            }(ASCFile())

            apiDelete(item: deleteFile) { fileObject, error in
                self.apiUpload(data: data, name: fileName, mimeType: mimeType, folderId: path, processing: processing)
            }
        } else {
            apiUpload(data: data, name: fileName, mimeType: mimeType, folderId: path, processing: processing)
        }
    }

    /// Create new document via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - name: The document title
    ///   - extension: The document extension
    ///   - folder: Parent folder
    ///   - completeon: a closure with result of operation or error
    func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let _ = googleUser else {
            completeon?(self, nil, false, ASCProviderError(msg: ErrorType.userUndefined.description))
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
            do {
                let templatPath = Path(templatePath)
                let data = try Data.read(from: Path(templatePath))
                var params: [String: Any] = [
                    "title" : fileTitle
                ]
                
                if let mime = templatPath.mime {
                    params["mime"] = mime
                }
                
                upload(folder.id, data: data, overwrite: false, params: params) { [weak self] provider, result, error, response in
                    guard let strongSelf = self else { return }
                    
                    if let error = error {
                        completeon?(strongSelf, nil, false, ASCProviderError(error))
                    } else if let file = result as? ASCFile {
                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                            "portal": "Direct - Google Drive",
                            "onDevice": false,
                            "type": "file",
                            "fileExt": file.title.fileExtension().lowercased()
                            ]
                        )
                        
                        completeon?(strongSelf, file, true, nil)
                    }
                }
            } catch {
                completeon?(self, nil, false, ASCProviderError(msg: ErrorType.upload.description))
            }
        }
    }
    
    /// Create new image via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - name: The image title
    ///   - folder: Parent folder
    ///   - data: upload data
    ///   - params: additional params
    ///   - processing: a closure with result of operation or error
    func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        createFile(name, in: folder, data: data, params: params, processing: processing)
    }

    /// Create new file via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - name: The image title
    ///   - folder: Parent folder
    ///   - data: upload data
    ///   - params: additional params
    ///   - processing: a closure with result of operation or error
    func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping ASCApiProgressHandler) {
        let params: [String: Any] = [
            "title" : name
        ]
        
        upload(folder.id, data: data, overwrite: false, params: params) { progress, result, error, response in
            if let _ = result {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": "Direct - Google Drive",
                    "onDevice": false,
                    "type": "file",
                    "fileExt": name.fileExtension()
                    ]
                )
            }
            processing(progress, result, error, response)
        }
    }

    /// Create folder via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - name: The folder title
    ///   - folder: Parent folder
    ///   - params: additional params
    ///   - completeon: a closure with result of operation or error
    func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {
        guard let _ = googleUser else {
            completeon?(self, nil, false, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }
        
        let metadata = GTLRDrive_File()
        metadata.name = name
        metadata.mimeType = "application/vnd.google-apps.folder"
        metadata.parents = [folder.id]
        
        let queryCreate = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: nil)
        queryCreate.fields = defaultObjectFields
        
        googleDriveService.executeQuery(queryCreate) { [weak self] _, result, error in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    completeon?(strongSelf, nil, false, error)
                    return
                }
                
                guard let folderObject = result as? GTLRDrive_File else {
                    completeon?(strongSelf, nil, false, ASCProviderError(msg: ErrorType.readFolder.description))
                    return
                }
                
                let parent = ASCFolder()
                parent.id = folderObject.parents?.first ?? ""
                
                let cloudFolder = ASCFolder()
                cloudFolder.id = folderObject.identifier ?? ""
                cloudFolder.rootFolderType = .googledriveAll
                cloudFolder.title = folderObject.name ?? ""
                cloudFolder.created = folderObject.createdTime?.date
                cloudFolder.updated = folderObject.modifiedTime?.date
                cloudFolder.createdBy = strongSelf.user
                cloudFolder.updatedBy = strongSelf.user
                cloudFolder.parent = parent
                cloudFolder.parentId = parent.id
                
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.createEntity, parameters: [
                    "portal": "Direct - Google Drive",
                    "onDevice": false,
                    "type": "folder"
                    ]
                )
                
                completeon?(strongSelf, cloudFolder, true, nil)
            }
        }
    }
    
    /// Rename entity via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - entity: The file or folder object
    ///   - newName: New title
    ///   - completeon: a closure with result of operation or error
    func rename(_ entity: ASCEntity, to newName: String, completeon: ASCProviderCompletionHandler?) {
        guard let _ = googleUser else {
            completeon?(self, nil, false, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }

        let metadata = GTLRDrive_File()
        metadata.name = newName
        
        if let file = entity as? ASCFile {
            let fileExtension = file.title.fileExtension()
            metadata.name = newName + (fileExtension.length < 1 ? "" : ".\(fileExtension)")
        }

        let queryRename = GTLRDriveQuery_FilesUpdate.query(withObject: metadata, fileId: entity.id, uploadParameters: nil)
        queryRename.fields = defaultObjectFields
        
        googleDriveService.executeQuery(queryRename) { [weak self] _, result, error in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    completeon?(strongSelf, nil, false, error)
                    return
                }
                
                if let file = entity as? ASCFile {
                    let fileExtension = file.title.fileExtension()
                    file.title = newName + (fileExtension.length < 1 ? "" : ".\(fileExtension)")
                    completeon?(strongSelf, file, true, nil)
                } else if let folder = entity as? ASCFolder {
                    folder.title = newName
                    completeon?(strongSelf, folder, true, nil)
                } else {
                    completeon?(strongSelf, nil, false, nil)
                }
            }
        }
    }
    
    /// Remove list of entities via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - entity: The file or folder object
    ///   - folder: The source folder
    ///   - completeon: a closure with result of operation or error
    func delete(_ entities: [ASCEntity], from folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        guard let _ = googleUser else {
            completeon?(self, nil, false, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }
        
        var lastError: Error?
        var results: [ASCEntity] = []
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for entity in entities {
            operationQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }
                let semaphore = DispatchSemaphore(value: 0)
                
                strongSelf.apiDelete(item: entity) { object, error in
                    if let error = error {
                        lastError = error
                    } else {
                        results.append(entity)
                    }
                    semaphore.signal()
                }
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

    /// Check before transfer items via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - items: The list of transfer object
    ///   - folder: The destination folder
    ///   - handler: a closure with result of operation or error
    func chechTransfer(items: [ASCEntity], to folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        handler?(.begin, nil, nil)
        handler?(.end, [], nil)
    }
    
    /// Transfer items of entities via asynchronous completion handler
    ///
    /// - Parameters:
    ///   - items: The list of transfer object
    ///   - folder: The destination folder
    ///   - handler: a closure with result of operation or error
    func transfer(items: [ASCEntity], to folder: ASCFolder, move: Bool, overwrite: Bool, handler: ASCEntityProgressHandler?) {
        var cancel = false
        
        guard let _ = googleUser else {
            handler?(.end, 1, nil, ErrorType.userUndefined.description, &cancel)
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
                
                self.apiCopy(item: entity, to: folder) { object, error in
                    if let error = error {
                        lastError = error
                    } else {
                        results.append(entity)
                    }
                    
                    if move {
                        // Delete original
                        self.apiDelete(item: entity) { object, error in
                            DispatchQueue.main.async(execute: {
                                handler?(.progress, Float(index + 1) / Float(items.count), entity, error?.localizedDescription, &cancel)
                            })
                            semaphore.signal()
                        }
                    } else {
                        DispatchQueue.main.async(execute: {
                            handler?(.progress, Float(index + 1) / Float(items.count), entity, error?.localizedDescription, &cancel)
                        })
                        semaphore.signal()
                    }
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
    
    // MARK: - Private
    
    /// Query metadata file info via Google Api
    ///
    /// - Parameters:
    ///   - item: the entity for fetch metadata
    ///   - complation: a closure with result of operation or error
    private func apiGetInfo(item: ASCEntity, _ complation: @escaping (_ fileObject: GTLRDrive_File?, _ error: Error?) -> Void) {
        guard let _ = googleUser else {
            complation(nil, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }
        
        let queryMetadata = GTLRDriveQuery_FilesGet.query(withFileId: item.id)
        queryMetadata.fields = defaultObjectFields
        
        googleDriveService.executeQuery(queryMetadata) { ticket, file, error in
            DispatchQueue.main.async {
                if let error = error {
                    complation(nil, error)
                } else if let fileObject = file as? GTLRDrive_File {
                    complation(fileObject, nil)
                } else {
                    complation(nil, nil)
                }
            }
        }
    }
    
    /// Copy file via Google Api
    ///
    /// - Parameters:
    ///   - item: the entity for copy
    ///   - complation: a closure with result of operation or error
    private func apiCopy(item: ASCEntity, to folder: ASCFolder, _ complation: @escaping (_ fileObject: GTLRDrive_File?, _ error: Error?) -> Void) {
        guard let _ = googleUser else {
            complation(nil, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }
        
        let metadata = GTLRDrive_File()
        metadata.name = (item as? ASCFile)?.title ?? (item as? ASCFolder)?.title ?? Date().iso8601
        metadata.parents = [folder.id]
        
        let queryDelete = GTLRDriveQuery_FilesCopy.query(withObject: metadata, fileId: item.id)
        queryDelete.fields = defaultObjectFields
        
        googleDriveService.executeQuery(queryDelete) { ticket, file, error in
            DispatchQueue.main.async {
                if let error = error {
                    complation(nil, error)
                } else if let fileObject = file as? GTLRDrive_File {
                    complation(fileObject, nil)
                } else {
                    complation(nil, nil)
                }
            }
        }
    }
    
    /// Delete file via Google Api
    ///
    /// - Parameters:
    ///   - item: the entity for delete
    ///   - complation: a closure with result of operation or error
    private func apiDelete(item: ASCEntity, _ complation: @escaping (_ fileObject: GTLRDrive_File?, _ error: Error?) -> Void) {
        guard let _ = googleUser else {
            complation(nil, ASCProviderError(msg: ErrorType.userUndefined.description))
            return
        }
        
        let queryDelete = GTLRDriveQuery_FilesDelete.query(withFileId: item.id)
        queryDelete.fields = defaultObjectFields
        
        googleDriveService.executeQuery(queryDelete) { ticket, file, error in
            DispatchQueue.main.async {
                if let error = error {
                    complation(nil, error)
                } else if let fileObject = file as? GTLRDrive_File {
                    complation(fileObject, nil)
                } else {
                    complation(nil, nil)
                }
            }
        }
    }
    
    /// Upload file via Google Api
    ///
    /// - Parameters:
    ///   - data: The data to uploaded
    ///   - name: The file name
    ///   - mimeType: The media's type
    ///   - folderId: The parent folder identifier
    ///   - complation: a closure with result of operation or error
    private func apiUpload(
        data: Data,
        name: String,
        mimeType: String,
        folderId: String,
        processing: @escaping ASCApiProgressHandler)
    {
        guard let _ = googleUser else {
            processing(0, nil, ASCProviderError(msg: ErrorType.upload.description), nil)
            return
        }
        
        let metadata = GTLRDrive_File()
        metadata.name = name
        metadata.parents = [folderId]
        
        let uploadParameters = GTLRUploadParameters(data: data, mimeType: mimeType)
        let queryCreate = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
        queryCreate.fields = defaultObjectFields
        
        let ticket = googleDriveService.executeQuery(queryCreate) { [weak self] ticket, file, error in
            DispatchQueue.main.async {
                if let error = error {
                    processing(1.0, nil, error, nil)
                } else if let fileObject = file as? GTLRDrive_File {
                    let fileSize: UInt64 = max(0, UInt64(truncating: fileObject.size ?? 0))
                    
                    let parent = ASCFolder()
                    parent.id = fileObject.parents?.first ?? ""
                    
                    let cloudFile = ASCFile()
                    cloudFile.id = fileObject.identifier ?? ""
                    cloudFile.rootFolderType = .googledriveAll
                    cloudFile.title = fileObject.name ?? ""
                    cloudFile.created = fileObject.createdTime?.date
                    cloudFile.updated = fileObject.modifiedTime?.date
                    cloudFile.createdBy = self?.user
                    cloudFile.updatedBy = self?.user
                    cloudFile.parent = parent
                    cloudFile.viewUrl = fileObject.identifier ?? ""
                    cloudFile.displayContentLength = String.fileSizeToString(with: fileSize)
                    cloudFile.pureContentLength = Int(fileSize)
                    
                    processing(1.0, cloudFile, nil, nil)
                } else {
                    processing(1.0, nil, nil, nil)
                }
            }
        }
        ticket.objectFetcher?.sendProgressBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            DispatchQueue.main.async {
                log.debug("progress: \(Double(totalBytesSent) / Double(max(1, totalBytesExpectedToSend)))")
                processing(Double(totalBytesSent) / Double(max(1, totalBytesExpectedToSend)), nil, nil, nil)
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
