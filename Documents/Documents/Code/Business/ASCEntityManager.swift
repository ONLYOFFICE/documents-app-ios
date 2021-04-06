//
//  ASCEntityManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/30/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit
import Firebase
import CoreServices

enum ASCEntityProcessStatus: String {
    case begin     = "ASCEntityCreateBegin"
    case progress  = "ASCEntityCreateProgress"
    case end       = "ASCEntityCreateEnd"
    case error     = "ASCEntityCreateError"
}

typealias ASCEntityHandler = (_ status: ASCEntityProcessStatus, _ result: Any?, _ error: String?) -> Void
typealias ASCEntityProgressHandler = (_ status: ASCEntityProcessStatus, _ progress: Float, _ result: Any?, _ error: String?, _ cancel: inout Bool) -> Void

class ASCEntityManager: NSObject, UITextFieldDelegate {
    public static let shared = ASCEntityManager()
    
    static private let maxTitle = 170
    static private let errorDomain = "ASCEntityManagerError"
    
    // MARK: - Public
    
    func createFile(for provider: ASCFileProviderProtocol, _ fileExtension: String, in folder: ASCFolder?, handler: ASCEntityHandler? = nil) {
        guard let folder = folder else {
            return
        }
        
        var fileName = NSLocalizedString("New Document", comment: "")
        
        if fileExtension == "xlsx" {
            fileName = NSLocalizedString("New Spreadsheet", comment: "")
        } else if fileExtension == "pptx" {
            fileName = NSLocalizedString("New Presentation", comment: "")
        }
        
        let alertController = UIAlertController(title: fileName, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
            }
        }
        let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: "")) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
                
                if var fileTitle = textField.text?.validPathName {
                    if fileTitle.length < 1 {
                        fileTitle = fileName
                    }
                    
                    handler?(.begin, nil, nil)

                    provider.createDocument(fileTitle, fileExtension: fileExtension, in: folder, completeon: { provider, file, success, error in
                        if let error = error {
                            handler?(.error, nil, ASCProviderError(error).localizedDescription)
                        } else if let file = file {
                            handler?(.end, file, nil)
                        } else {
                            handler?(.error, nil, NSLocalizedString("Can not create file with this name.", comment: ""))
                        }
                    })
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.text = fileName
            
            textField.add(for: .editingChanged, {
                createAction.isEnabled = (textField.text?.trim().length)! > 0
            })
            
            delay(seconds: 0.2) {
                textField.selectAll(nil)
            }
        }
        
        if let topVC = ASCViewControllerManager.shared.topViewController {
            alertController.view.tintColor = ASCConstants.Colors.brend
            topVC.present(alertController, animated: true, completion: nil)
        }
    }
    
    func createFolder(for provider: ASCFileProviderProtocol, in folder: ASCFolder?, handler: ASCEntityHandler? = nil) {
        guard let folder = folder else {
            return
        }
        
        let folderName = NSLocalizedString("New Folder", comment: "")
        
        let alertController = UIAlertController(title: NSLocalizedString("New Folder", comment: ""), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
            }
        }
        let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: "")) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil

                if var folderTitle = textField.text?.validPathName {
                    if folderTitle.length < 1 {
                        folderTitle = folderName
                    }
                    
                    handler?(.begin, nil, nil)

                    provider.createFolder(folderTitle, in: folder, params: nil, completeon: { provider, folder, success, error in
                        if let error = error {
                            handler?(.error, nil, ASCProviderError(error).localizedDescription)
                        } else if let folder = folder {
                            handler?(.end, folder, nil)
                        } else {
                            handler?(.error, nil, NSLocalizedString("Can not create folder with this name.", comment: ""))
                        }
                    })
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.text = folderName
            
            textField.add(for: .editingChanged, {
                createAction.isEnabled = (textField.text?.trim().length)! > 0
            })
            
            delay(seconds: 0.2) {
                textField.selectAll(nil)
            }
        }
        
        if let topVC = ASCViewControllerManager.shared.topViewController {
            alertController.view.tintColor = ASCConstants.Colors.brend
            topVC.present(alertController, animated: true, completion: nil)
        }
    }

    func createFile(
        for provider: ASCFileProviderProtocol,
        in folder: ASCFolder?,
        data: Data,
        name: String,
        params: [String: Any]?,
        handler: ASCEntityProgressHandler? = nil)
    {
        guard let folder = folder else {
            return
        }

        var cancel = false

        handler?(.begin, 0, nil, nil, &cancel)

        var params: [String: Any] = [
            "mime": "application/octet-stream"
        ]
        let pathExtension = name.fileExtension()

        if  let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            params["mime"] = mimetype as String
        }

        provider.createFile(name, in: folder, data: data, params: params) { (progress, result, error, response) in
            if let error = error {
                if let response = response {
                    handler?(.error, Float(progress), nil, provider.errorMessage(by: response), &cancel)
                } else {
                    handler?(.error, Float(progress), nil, ASCProviderError(error).localizedDescription, &cancel)
                }
            } else {
                if let result = result as? [String: Any] {
                    let file = ASCFile(JSON: result)
                    handler?(.end, 1, file, nil, &cancel)
                } else if let result = result as? ASCFile {
                    handler?(.end, 1, result, nil, &cancel)
                } else {
                    handler?(.progress, Float(progress), nil, nil, &cancel)
                }
            }
        }
    }

    func createImage(
        for provider: ASCFileProviderProtocol,
        in folder: ASCFolder?,
        imageData: Data,
        fileExtension: String,
        handler: ASCEntityProgressHandler? = nil)
    {
        guard let folder = folder else {
            return
        }
        
        var cancel = false
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        
        let fileTitle = formatter.string(from: Date()) + "." + fileExtension
//        let params: [String: Any] = [
//            "title": fileTitle,
//            "mime": "image/jpg"
//            ]

        handler?(.begin, 0, nil, nil, &cancel)

        provider.createImage(fileTitle, in: folder, data: imageData, params: nil) { (progress, result, error, response) in
            if let error = error {
                if let response = response {
                    handler?(.error, Float(progress), nil, provider.errorMessage(by: response), &cancel)
                } else {
                    handler?(.error, Float(progress), nil, ASCProviderError(error).localizedDescription, &cancel)
                }
            } else {
                if let result = result as? [String: Any] {
                    let file = ASCFile(JSON: result)
                    handler?(.end, 1, file, nil, &cancel)
                } else if let result = result as? ASCFile {
                    handler?(.end, 1, result, nil, &cancel)
                } else {
                    handler?(.progress, Float(progress), nil, nil, &cancel)
                }
            }
        }
    }
    
    func delete(for provider: ASCFileProviderProtocol, entities: [AnyObject], from folder: ASCFolder, handler: ASCEntityHandler? = nil) {
        let fromFolder = folder

        handler?(.begin, nil, nil)
        
        var isDeviceEntities = true
        
        // Detect type of entities
        if let firstEntity = entities.first {
            let firstFile = firstEntity as? ASCFile
            let firstFolder = firstEntity as? ASCFolder
            
            isDeviceEntities = firstFile?.device ?? firstFolder?.device ?? true
        } else {
            handler?(.end, nil, nil)
            return
        }
        
        if isDeviceEntities {
            for entity in entities {
                if let file = entity as? ASCFile {
                    if fromFolder.rootFolderType == .deviceTrash {
                        ASCLocalFileHelper.shared.removeFile(Path(file.id))
                    } else {
                        guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path.userTrash + file.title) else {
                            handler?(.error, nil, NSLocalizedString("Could not delete the file.", comment: ""))
                            return
                        }
                        
                        if let _ = ASCLocalFileHelper.shared.move(from: Path(file.id), to: filePath) {
                            handler?(.error, nil, NSLocalizedString("Could not delete the file.", comment: ""))
                            return
                        }
                    }
                } else if let folder = entity as? ASCFolder {
                    if fromFolder.rootFolderType == .deviceTrash {
                        ASCLocalFileHelper.shared.removeDirectory(Path(folder.id))
                    } else {
                        guard let folderPath = ASCLocalFileHelper.shared.resolve(folderPath: Path.userTrash + folder.title) else {
                            handler?(.error, nil, NSLocalizedString("Could not delete the folder.", comment: ""))
                            return
                        }
                        
                        if let _ = ASCLocalFileHelper.shared.move(from: Path(folder.id), to: folderPath) {
                            handler?(.error, nil, NSLocalizedString("Could not delete the folder.", comment: ""))
                            return
                        }
                    }
                }
            }
            
            handler?(.end, entities, nil)
        } else {
            if let entities = entities as? [ASCEntity] {
                provider.delete(entities, from: folder) { provider, results, success, error in
                    if let error = error {
                        handler?(.error, results, ASCProviderError(error).localizedDescription)
                    } else {
                        handler?(.end, results, nil)
                    }
                }
            }
        }
    }
    
    func delete(for provider: ASCFileProviderProtocol, entity: AnyObject?, handler: ASCEntityHandler? = nil) {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
//        let parentFolder = file?.parent ?? folder?.parent
        
        if file == nil && folder == nil {
            handler?(.error, nil, NSLocalizedString("Unknown item type.", comment: ""))
            return
        }
        
        let isDevice =  (file?.device ?? folder?.device)!
        let entityTitle = file?.title ?? folder?.title
        
        handler?(.begin, nil, nil)
        
        if isDevice {
            if let deviceFile = file {
                if deviceFile.rootFolderType == .onlyofficeTrash {
                    ASCLocalFileHelper.shared.removeFile(Path(deviceFile.id))
                } else {
                    guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path.userTrash + entityTitle!) else {
                        handler?(.error, nil, NSLocalizedString("Could not delete the file.", comment: ""))
                        return
                    }
                    
                    if let _ = ASCLocalFileHelper.shared.move(from: Path(deviceFile.id), to: filePath) {
                        handler?(.error, nil, NSLocalizedString("Could not delete the file.", comment: ""))
                        return
                    }
                }
                handler?(.end, deviceFile, nil)
            } else if let deviceFolder = folder {
                if deviceFolder.rootFolderType == .onlyofficeTrash {
                    ASCLocalFileHelper.shared.removeDirectory(Path(deviceFolder.id))
                } else {
                    guard let folderPath = ASCLocalFileHelper.shared.resolve(folderPath: Path.userTrash + entityTitle!) else {
                        handler?(.error, nil, NSLocalizedString("Could not delete the folder.", comment: ""))
                        return
                    }
                    
                    if let _ = ASCLocalFileHelper.shared.move(from: Path(deviceFolder.id), to: folderPath) {
                        handler?(.error, nil, NSLocalizedString("Could not delete the folder.", comment: ""))
                        return
                    }
                }
                handler?(.end, deviceFolder, nil)
            }
        } else {
            let isShareEntity = (file?.rootFolderType == .onlyofficeShare) || (folder?.rootFolderType == .onlyofficeShare)
            var requestPath = String(format: (file != nil ? ASCOnlyOfficeApi.apiFileId : ASCOnlyOfficeApi.apiFolderId), (file != nil ? file?.id : folder?.id) ?? "")
            var parameters: [String: Any]? = nil

            if isShareEntity {
                requestPath = ASCOnlyOfficeApi.apiBatchShare
                parameters = file != nil ? ["fileIds" : [file?.id]] : ["folderIds": [folder?.id]]
            }
            
            ASCOnlyOfficeApi.delete(requestPath, parameters: parameters, completion: { (result, error, response) in
                if error != nil {
                    handler?(.error, nil, ASCOnlyOfficeApi.errorMessage(by: response!))
                } else {
                    if result != nil {
                        handler?(.end, entity, nil)
                    } else {
                        handler?(.end, nil, nil)
                    }
                }
            })
        }
    }
    
    func rename(for provider: ASCFileProviderProtocol, entity: AnyObject?, handler: ASCEntityHandler? = nil) {
        let file = entity as? ASCFile
        let folder = entity as? ASCFolder
        
        if file == nil && folder == nil {
            handler?(.error, nil, NSLocalizedString("Unknown item type.", comment: ""))
            return
        }
        
        let entityTitle = file?.title ?? folder?.title
        let alertController = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
            }
        }
        let renameAction = UIAlertAction(title: NSLocalizedString("Rename", comment: "")) { (action) in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
                
                if let newTitle = textField.text?.validPathName {
                    if newTitle.length < 1 {
                        handler?(.error, nil, NSLocalizedString("Empty name.", comment: ""))
                        return
                    }
                    
                    handler?(.begin, nil, nil)

                    provider.rename(file ?? folder!, to: newTitle, completeon: { provider, entity, success, error in
                        if !success {
                            handler?(.error, nil, error?.localizedDescription ?? NSLocalizedString("Rename failed.", comment: ""))
                        } else {
                            handler?(.end, entity, nil)
                        }
                    })
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(renameAction)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.text = entityTitle?.fileName()
            
            textField.add(for: .editingChanged, {
                renameAction.isEnabled = (textField.text?.trim().length)! > 0
            })
            
            delay(seconds: 0.2) {
                textField.selectAll(nil)
            }
        }
        
        if let topVC = ASCViewControllerManager.shared.topViewController {
            alertController.view.tintColor = ASCConstants.Colors.brend
            topVC.present(alertController, animated: true, completion: nil)
        }
    }
    
    func favorite(for provider: ASCFileProviderProtocol, entity: AnyObject?, favorite: Bool, handler: ASCEntityHandler? = nil) {
        guard let file = entity as? ASCFile else {
            handler?(.error, nil, NSLocalizedString("Unknown item type.", comment: ""))
            return
        }
        
        handler?(.begin, nil, nil)

        provider.favorite(file, favorite: favorite) { provider, entity, success, error in
            if !success {
                handler?(.error, nil, error?.localizedDescription ?? NSLocalizedString("Set favorite failed.", comment: ""))
            } else {
                handler?(.end, entity, nil)
            }
        }
    }
    
    func download(for provider: ASCFileProviderProtocol, entity: AnyObject?, handler: ASCEntityProgressHandler? = nil) {
        var cancel = false
        
        guard let file = entity as? ASCFile else {
            handler?(.error, 1, nil, NSLocalizedString("Could not download object.", comment: ""), &cancel)
            return
        }
        
        let fileTitle = file.title
        let destination = Path.userDocuments + fileTitle
        
        if destination.exists {
            handler?(.error, 1, nil, NSLocalizedString("A file with a similar name already exists in the document directory on the device.", comment: ""), &cancel)
            return
        }
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        provider.download(file.viewUrl ?? "", to: URL(fileURLWithPath:destination.rawValue)) { (progress, result, error, response) in
            if cancel {
                ASCLocalFileHelper.shared.removeFile(destination)
                handler?(.end, 1, nil, nil, &cancel)
                return
            }
            
            if let error = error {
                ASCLocalFileHelper.shared.removeFile(destination)
                handler?(.error, Float(progress), nil, ASCProviderError(error).localizedDescription, &cancel) // ?? ASCOnlyOfficeApi.errorMessage(by: response!)
            } else if nil != result {
                // Create entity info
                let owner = ASCUser()
                owner.displayName = UIDevice.displayName
                
                let file = ASCFile()
                file.id = destination.rawValue
                file.rootFolderType = .deviceDocuments
                file.title = destination.fileName
                file.created = destination.creationDate
                file.updated = destination.modificationDate
                file.createdBy = owner
                file.updatedBy = owner
                file.device = true
                file.displayContentLength = String.fileSizeToString(with: destination.fileSize ?? 0)
                file.pureContentLength = Int(destination.fileSize ?? 0)
                
                handler?(.end, 1, file, nil, &cancel)
            } else {
                handler?(.progress, Float(progress), nil, nil, &cancel)
            }
        }
    }
    
    func downloadTemp(for provider: ASCFileProviderProtocol, entity: AnyObject?, handler: ASCEntityProgressHandler? = nil) {
        var cancel = false
        
        guard let file = entity as? ASCFile else {
            handler?(.error, 1, nil, NSLocalizedString("Could not download object.", comment: ""), &cancel)
            return
        }
        
        let fileTitle = file.title
        let destination = Path.userTemporary + fileTitle
     
        ASCLocalFileHelper.shared.removeFile(Path.init(url: URL(fileURLWithPath:destination.rawValue))!)
       
        if destination.exists {
            handler?(.error, 1, nil, NSLocalizedString("A file with a similar name already exists in the document directory on the device.", comment: ""), &cancel)
            return
        }
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        provider.download(file.viewUrl ?? "", to: URL(fileURLWithPath:destination.rawValue)) { progress, result, error, response in
            if cancel {
                handler?(.end, 1, nil, nil, &cancel)
                return
            }
            
            if nil != error {
                if let response = response {
                    handler?(.error, Float(progress), nil, ASCOnlyOfficeApi.errorMessage(by: response), &cancel)
                } else {
                    handler?(.error, Float(progress), nil, NSLocalizedString("Could not download object.", comment: ""), &cancel)
                }
            } else if nil != result {
                // Create entity info
                let owner = ASCUser()
                owner.displayName = UIDevice.displayName
                
                let file = ASCFile()
                file.id = destination.rawValue
                file.rootFolderType = .deviceDocuments
                file.title = destination.fileName
                file.created = destination.creationDate
                file.updated = destination.modificationDate
                file.createdBy = owner
                file.updatedBy = owner
                file.device = true
                file.displayContentLength = String.fileSizeToString(with: destination.fileSize ?? 0)
                file.pureContentLength = Int(destination.fileSize ?? 0)
                
                handler?(.end, 1, file, nil, &cancel)
            } else {
                handler?(.progress, Float(progress), nil, nil, &cancel)
            }
        }
    }

    func duplicate(file: ASCFile, to folder: ASCFolder, handler: ASCEntityProgressHandler? = nil) {
        var cancel = false
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        if folder.device {
            let fileName = file.title.fileName()
            let fileExtension = file.title.fileExtension()
            
            guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: Path(folder.id) + (fileName + "." + fileExtension)) else {
                handler?(.error, 1, nil, NSLocalizedString("Can not duplicate the file.", comment: ""), &cancel)
                return
            }
            
            if let error = ASCLocalFileHelper.shared.copy(from: Path(file.id), to: filePath) {
                handler?(.error, 1, nil, ASCProviderError(error).localizedDescription, &cancel)
            } else {
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
                
                handler?(.end, 1, file, nil, &cancel)
            }
        } else {
            let parameters: [String: Any] = [
                "destFolderId": folder.id,
                "fileIds": file.id,
                "conflictResolveType": 2
            ]
            
            ASCOnlyOfficeApi.put(ASCOnlyOfficeApi.apiBatchCopy, parameters: parameters) { (result, error, response) in
                if error != nil {
                    handler?(.error, 1, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
                } else {
                    func checkOperation() {
                        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiFileOperations) { (result, error, response) in
                            if error != nil {
                                handler?(.error, 1, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
                            } else {
                                if let result = result as? [Any], let entityFromResponse = result.first as? [String: Any] {
                                    if let progressResponse = entityFromResponse["progress"] as? Int {
                                        handler?(.progress, Float(progressResponse) / 100.0, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
                                        
                                        if progressResponse >= 100 {
                                            if let files = entityFromResponse["files"] as? [[String: Any]], files.count > 1, let file = ASCFile(JSON: files[1]) {
                                                handler?(.end, 1, file, nil, &cancel)
                                            }
                                        } else {
                                            Thread.sleep(forTimeInterval: 1)
                                            checkOperation();
                                        }
                                    } else {
                                        handler?(.error, 1, nil, NSLocalizedString("Unknown API response.", comment: ""), &cancel)
                                    }
                                }
                            }
                        }
                    }
                    checkOperation()
                }
            }
        }
    }
    
    func emptyTrash(handler: ASCEntityProgressHandler? = nil) {
        var cancel = false
        handler?(.begin, 0, nil, nil, &cancel)
        
        // Empty local trash
        let trashItems = ASCLocalFileHelper.shared.entityList(Path.userTrash)
        
        for item in trashItems {
            ASCLocalFileHelper.shared.removeFile(item)
        }
        
        handler?(.progress, 0.5, nil, nil, &cancel)
        
        // Empty cloud trash
        ASCOnlyOfficeApi.put(ASCOnlyOfficeApi.apiEmptyTrash) { (result, error, response) in
            if error != nil {
                handler?(.error, 1, nil, ASCOnlyOfficeApi.errorMessage(by: response!), &cancel)
            } else {
                handler?(.end, 1, nil, nil, &cancel)
            }
        }
    }

    func uploadEdit(for provider: ASCFileProviderProtocol, file: ASCFile, originalFile: ASCFile, handler: ASCEntityProgressHandler? = nil) {
        var cancel = false

        handler?(.begin, 0, nil, nil, &cancel)
        
        let dataFile = DataFile(path: Path(file.id))
        var content: Data?
        
        do {
            content = try dataFile.read()
        } catch {
            handler?(.error, 1, nil, NSLocalizedString("Could not read data from the file.", comment: ""), &cancel)
            return
        }
        
        guard let data = content else {
            handler?(.error, 1, nil, NSLocalizedString("Could not read data from the file.", comment: ""), &cancel)
            return
        }

        let params: [String: Any] = [
            "mime": Path(file.id).mime ?? DEFAULT_MIME_TYPE
        ]

        if originalFile.title == file.title {
            // Modify exist file
            let path = originalFile.id

            provider.modify(path, data: data, params: params) { progress, result, error, response in
                if error != nil {
                    if let response = response {
                        handler?(.error, Float(progress), nil, provider.errorMessage(by: response), &cancel)
                    } else {
                        handler?(.error, Float(progress), nil, NSLocalizedString("The server is not available.", comment: ""), &cancel)
                    }
                } else {
                    if let file = result as? ASCFile {
                        handler?(.end, 1, file, nil, &cancel)
                        NotificationCenter.default.post(name: ASCConstants.Notifications.updateFileInfo, object: result)
                    } else {
                        handler?(.progress, Float(progress), nil, nil, &cancel)
                    }
                }
            }
        } else if let parent = originalFile.parent {
            // Upload new file
            let params: [String: Any] = [
                "title": file.title
            ]

            provider.upload(parent.id,
                            data: data,
                            overwrite: true,
                            params: params,
                            processing:
                { progress, result, error, response in
                    if nil != error || nil != result {
                        if let error = error {
                            log.error("Upload file \(file.title) - \(error.localizedDescription)")
                            if let response = response {
                                handler?(.error, Float(progress), nil, provider.errorMessage(by: response), &cancel)
                            } else {
                                handler?(.error, Float(progress), nil, NSLocalizedString("The server is not available.", comment: ""), &cancel)
                            }
                        }

                        if let result = result as? [String: Any] {
                            if let file = ASCFile(JSON: result) {
                                handler?(.end, 1, file, nil, &cancel)
                                NotificationCenter.default.post(name: ASCConstants.Notifications.updateFileInfo, object: result)
                            }
                        } else if let file = result as? ASCFile {
                            handler?(.end, 1, file, nil, &cancel)
                            NotificationCenter.default.post(name: ASCConstants.Notifications.updateFileInfo, object: result)
                        } else {
                            handler?(.progress, Float(progress), nil, nil, &cancel)
                        }
                    }
            })
        } else {
            handler?(.error, 1, nil, NSLocalizedString("Could not read data from the file.", comment: ""), &cancel)
        }
    }

    func transfer(from: (items: [ASCEntity], provider: ASCFileProviderProtocol),
                  to: (folder: ASCFolder, provider: ASCFileProviderProtocol),
                  move: Bool = false,
                  handler: @escaping ((_ progress: Float, _ complation: Bool, _ success: Bool, _ newItems: [ASCEntity]?, _ error: Error?, _ cancel: inout Bool) -> Void) )
    {
        var cancel = false

        guard let srcParent = (from.items.first as? ASCFile)?.parent ?? (from.items.first as? ASCFolder)?.parent else {
            handler(1, true, false, nil, nil, &cancel)
            return
        }

        let tempPath = Path.userTemporary + UUID().uuidString

        // Create download temporary
        ASCLocalFileHelper.shared.createDirectory(tempPath)

        var params: [String: Any] = [:]
        var structures: [(
            srcFolder: ASCFolder,
            localFolder: ASCFolder?,
            dstFolder: ASCFolder?,
            items: [ASCEntity]
            )] = [(
                srcFolder: srcParent,
                localFolder: nil,
                dstFolder: to.folder,
                items: from.items
                )]
        let srcProvider = from.provider
        let dstProvider = to.provider
        var newItems: [ASCEntity] = []

        let srcAbsolutePath: ((ASCEntity)-> String) = { entity in
            var localPath:[String] = [(entity as? ASCFile)?.title ?? (entity as? ASCFolder)?.title ?? ""]
            var parent = (entity as? ASCFile)?.parent ?? (entity as? ASCFolder)?.parent

            while let folder = structures.first(where: { $0.srcFolder.id == parent?.id })?.srcFolder {
                localPath.append(folder.title)
                parent = folder.parent
            }

            return localPath.reversed().joined(separator: "/")
        }

        var commonProgress: Float = 0.15

        let forceExit = {
            if commonProgress < 1 {
                commonProgress = 1
                handler(commonProgress, true, false, nil, nil, &cancel)

                srcProvider.cancel()
                dstProvider.cancel()
            }
            
            // Cleanup temporary
            ASCLocalFileHelper.shared.removeDirectory(tempPath)
        }
        
        let showNetworkErrorIfNeeded = {
            if !ASCNetworkReachability.shared.isReachable {
                ASCBanner.shared.showError(
                    title: NSLocalizedString("No network", comment: ""),
                    message: NSLocalizedString("Check your internet connection", comment: "")
                )
            }
        }

        // Read Structure

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        operationQueue.addOperation {
            let readQueue = OperationQueue()

            func read(folder: ASCFolder, level: Int = 0) {
                readQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    srcProvider.fetch(for: folder, parameters: params) { provider, result, success, error in
                        if cancel {
                            forceExit()
                            semaphore.signal()
                            return
                        }

                        if success {
                            // Folders
                            let folders: [ASCFolder] = provider.items.compactMap { $0 as? ASCFolder }
                            for folder in folders {
                                read(folder: folder, level: level + 1)
                            }

                            // Files
                            // let files = provider.items.compactMap { $0 as? ASCFile }

                            structures.append((
                                srcFolder: folder,
                                localFolder: nil,
                                dstFolder: nil,
                                items: provider.items))
                        }

                        handler(commonProgress, false, false, nil, nil, &cancel)
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }

            let rootFolders = structures.first?.items.compactMap({ $0 as? ASCFolder }) ?? []
            for folder in rootFolders {
                read(folder: folder)
            }

            readQueue.waitUntilAllOperationsAreFinished()
        }

        // Download
        
        var downloadErrorFiles: [ASCFile] = []

        operationQueue.addOperation {
            if cancel {
                forceExit()
                return
            }

            // Create folders structure localy
            for (index, structure) in structures.enumerated() {
                let localPath = tempPath + srcAbsolutePath(structure.srcFolder)

                ASCLocalFileHelper.shared.createDirectory(localPath)

                let localFolder = ASCFolder()
                localFolder.id = localPath.rawValue
                localFolder.title = structure.srcFolder.title

                structures[index].localFolder = localFolder
            }

            // Downloading files
            let files = Array(structures
                .compactMap({ $0.items.compactMap({ $0 as? ASCFile }) })
                .joined())

            var localProgress: Float = 0
            var processedFiles = 0
            let sizeOfCommonProgress: Float = 0.2

            let downloadQueue = OperationQueue()
            //            downloadQueue.maxConcurrentOperationCount = 1

            for file in files {
                let localPath = tempPath + srcAbsolutePath(file)

                downloadQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)

                    srcProvider.download(file.viewUrl ?? "", to: URL(fileURLWithPath: localPath.rawValue)) { progress, result, error, response in
                        if cancel {
                            forceExit()
                            semaphore.signal()
                            return
                        }

                        let normalizeCurrentProgress = sizeOfCommonProgress / Float(files.count) * Float(progress)
                        handler(commonProgress + localProgress + normalizeCurrentProgress, false, false, nil, nil, &cancel)

                        if nil != error || nil != result {
                            if let error = error {
                                log.error("Download file: \(file.title) - \(error.localizedDescription)")
                                
                                if srcProvider.type != .local {
                                    showNetworkErrorIfNeeded()
                                }
                                
                                if let structureIndex = structures.firstIndex(where: { $0.items.contains(where: { ($0 as? ASCFile)?.viewUrl == file.viewUrl }) }) {
                                    if let index = structures[structureIndex].items.firstIndex(where: { ($0 as? ASCFile)?.viewUrl == file.viewUrl }) {
                                        structures[structureIndex].items.remove(at: index)
                                    }
                                }
                                
                                downloadErrorFiles.append(file)
                            }

                            processedFiles = processedFiles + 1
                            localProgress = sizeOfCommonProgress * Float(processedFiles) / Float(files.count)
                            handler(commonProgress + localProgress, false, false, nil, nil, &cancel)

                            semaphore.signal()
                        } else {
                            log.debug("Download progress: \(file.title) - \(Int(Float(progress) * 100))")
                        }
                    }
                    semaphore.wait()
                }
            }

            downloadQueue.waitUntilAllOperationsAreFinished()

            commonProgress = commonProgress + localProgress
            handler(commonProgress, false, false, nil, nil, &cancel)
        }

        // Create structure of folders

        operationQueue.addOperation {
            if cancel {
                forceExit()
                return
            }

            let sizeOfCommonProgress: Float = 0.2

            let createQueue = OperationQueue()
            createQueue.maxConcurrentOperationCount = 1

            func create(srcFolder: ASCFolder, in parent: ASCFolder) {
                createQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    dstProvider.createFolder(srcFolder.title, in: parent, params: nil, completeon: { provider, folder, success, error in
                        if cancel {
                            forceExit()
                            semaphore.signal()
                            return
                        }

                        if let error = error {
                            log.error("Create folder: \(error.localizedDescription)")
                            if dstProvider.type != .local {
                                showNetworkErrorIfNeeded()
                            }
                        } else if let folder = folder as? ASCFolder {
                            if let index = structures.firstIndex(where: { $0.srcFolder.id == srcFolder.id }) {
                                structures[index].dstFolder = folder
                                newItems.append(folder)
                            }
                        } else {
                            log.error("Create folder: \(NSLocalizedString("Can not create folder with this name.", comment: ""))")
                        }
                        semaphore.signal()
                    })
                    semaphore.wait()
                }
            }

            for structure in structures {
                let folders = structure.items.compactMap({ $0 as? ASCFolder })

                for folder in folders {
                    if let parent = folder.parent {
                        if let dstParentFolder = structures.first(where: { $0.srcFolder.id == parent.id })?.dstFolder {
                            create(srcFolder: folder, in: dstParentFolder)
                            createQueue.waitUntilAllOperationsAreFinished()
                        }
                    }
                }
            }

            commonProgress = commonProgress + sizeOfCommonProgress
            handler(commonProgress, false, false, nil, nil, &cancel)
        }

        // Upload files

        var uploadErrorFiles: [ASCFile] = []
        
        operationQueue.addOperation {
            if cancel {
                forceExit()
                return
            }

            let sizeOfCommonProgress: Float = 0.2
            var localProgress: Float = 0
            var processedFiles = 0

            let uploadQueue = OperationQueue()
            //            uploadQueue.maxConcurrentOperationCount = 1

            let fileCount = Array(structures
                .compactMap({ $0.items.compactMap({ $0 as? ASCFile }) })
                .joined()).count

            for structure in structures {
                if let dstFolder = structure.dstFolder, let localFolder = structure.localFolder {
                    let files = structure.items.compactMap({ $0 as? ASCFile })

                    for file in files {
                        let params: [String: Any] = [
                            "title": file.title
                        ]
                        let localFilePath = Path(localFolder.id) + file.title
                        let dataFile = DataFile(path: localFilePath)
                        var content: Data?

                        do {
                            content = try dataFile.read()
                        } catch {
                            log.error("Upload file: Read local data from: \(localFilePath.rawValue)")
                            uploadErrorFiles.append(file)
                            continue
                        }

                        if let data = content {
                            uploadQueue.addOperation {
                                let semaphore = DispatchSemaphore(value: 0)
                                dstProvider.upload(dstFolder.id,
                                                   data: data,
                                                   overwrite: true,
                                                   params: params,
                                                   processing:
                                    { progress, result, error, response in
                                        if cancel {
                                            forceExit()
                                            semaphore.signal()
                                            return
                                        }

                                        let normalizeCurrentProgress = sizeOfCommonProgress / Float(fileCount) * Float(progress)
                                        handler(commonProgress + localProgress + normalizeCurrentProgress, false, false, nil, nil, &cancel)

                                        if nil != error || nil != result {
                                            if let error = error {
                                                log.error("Upload file \(file.title) - \(error.localizedDescription)")
                                                if dstProvider.type != .local {
                                                    showNetworkErrorIfNeeded()
                                                }
                                                uploadErrorFiles.append(file)
                                            }

                                            if let result = result as? [String: Any] {
                                                if let file = ASCFile(JSON: result) {
                                                    newItems.append(file)
                                                }
                                            } else if let file = result as? ASCFile {
                                                newItems.append(file)
                                            }

                                            processedFiles = processedFiles + 1
                                            localProgress = sizeOfCommonProgress * Float(processedFiles) / Float(fileCount)
                                            handler(commonProgress + localProgress, false, false, nil, nil, &cancel)

                                            semaphore.signal()
                                        }
                                }
                                )
                                semaphore.wait()
                            }
                        }
                    }
                }
            }

            uploadQueue.waitUntilAllOperationsAreFinished()

            commonProgress = commonProgress + localProgress
            handler(commonProgress, false, false, nil, nil, &cancel)
            
            let errorFiles = downloadErrorFiles + uploadErrorFiles
            if errorFiles.count > 0 {
                let errorMsg = move
                    ? NSLocalizedString("Failed to move: %@", comment: "")
                    : NSLocalizedString("Failed to copy: %@", comment: "")
                let errorFileTitles = (downloadErrorFiles + uploadErrorFiles)
                    .map { $0.title }
                    .withoutDuplicates()
                    .joined(separator: ", ")
                    .truncated(toLength: 100)
                handler(1, true, false, nil, ASCProviderError(msg: String(format: errorMsg, errorFileTitles)), &cancel)
            }
        }

        // Remove originals

        operationQueue.addOperation {
            if cancel {
                forceExit()
                return
            }

            //            log.debug(to.folder)
            //            log.debug(newItems)

            let appendItems = newItems.filter({ ($0 as? ASCFile)?.parent?.uid == to.folder.uid || ($0 as? ASCFolder)?.parent?.uid == to.folder.uid })
            //            log.debug(appendItems)

            if move {
                let deleteQueue = OperationQueue()
                deleteQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    delay(seconds: 0.01, completion: {
                        let errorFiles = downloadErrorFiles + uploadErrorFiles
                        let errorFilesUids = errorFiles.map { $0.uid }
                        let movedItems = from.items.filter { !errorFilesUids.contains($0.uid) }
                        
                        srcProvider.delete(movedItems, from: srcParent, completeon: { provider, result, success, error in
                            semaphore.signal()
                        })
                    })
                    semaphore.wait()
                }

                deleteQueue.waitUntilAllOperationsAreFinished()

                // Done
                handler(1, true, true, appendItems, nil, &cancel)
            } else {
                // Done
                handler(1, true, true, appendItems, nil, &cancel)
            }
        }
        
        // Cleanup temporary
        operationQueue.addOperation {
            ASCLocalFileHelper.shared.removeDirectory(tempPath)
        }
    }
    
    // MARK: - UITextField Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isFirstResponder {
            if let primaryLanguage = textField.textInputMode?.primaryLanguage, primaryLanguage == "emoji" {
                return false
            }
        }
        
        if let nsString = textField.text as NSString? {
            var newString = nsString.replacingCharacters(in: range, with: string)
            let newStringLenght = newString.length
            
            if newStringLenght < 1 {
                return true
            }
            
            newString = newString.trimmingCharacters(in: CharacterSet(charactersIn: String.invalidTitleChars))
            
            if newStringLenght != newString.length {
                return false
            }
            
            return newString.length < ASCEntityManager.maxTitle
        }
        
        return false
    }
}
