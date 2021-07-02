//
//  ASCSharingOptionsInteractor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingOptionsBusinessLogic {
    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType)
}

protocol ASCSharingOptionsDataStore {
    var currentUser: ASCUser? { get }
    var sharedInfoItems: [ASCShareInfo] { get }
}

class ASCSharingOptionsInteractor: ASCSharingOptionsBusinessLogic, ASCSharingOptionsDataStore {
    
    var presenter: ASCSharingOptionsPresentationLogic?
    
    var currentUser: ASCUser?
    var sharedInfoItems: [ASCShareInfo] = []
    
    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType) {
        switch request {
        case .loadRightHolders(entity: let entity):
            loadCurrentUser()
            loadSharedInfoItems(entity: entity)
        case .clearData:
            currentUser = nil
            sharedInfoItems = []
        }
    }
    
    private func loadCurrentUser() {
        currentUser = ASCFileManager.onlyofficeProvider?.user
    }
    
    private func loadSharedInfoItems(entity: ASCEntity?) {
        guard let entity = entity else {
            presenter?.presentData(response: .presentRightHolders(sharedInfoItems: [], currentUser: currentUser))
            return
        }
        
        guard let apiRequest = makeApiRequest(entity: entity) else {
            presenter?.presentData(response: .presentRightHolders(sharedInfoItems: [], currentUser: currentUser))
            return
        }

        ASCOnlyOfficeApi.get(apiRequest) { (results, error, response) in
            if let results = results as? [[String: Any]] {

                for item in results {
                    var sharedItem = ASCShareInfo()
                    
                    sharedItem.access = ASCShareAccess(item["access"] as? Int ?? 0)
                    sharedItem.locked = item["isLocked"] as? Bool ?? false
                    sharedItem.owner = item["isOwner"] as? Bool ?? false

                    if let sharedTo = item["sharedTo"] as? [String: Any] {
                        
                        // Link for portal users
                        sharedItem.shareLink = sharedTo["shareLink"] as? String
                        if let _ = sharedItem.shareLink {
                            continue
                        }
                        
                        if let _ = sharedTo["userName"] {
                            sharedItem.user = ASCUser(JSON: sharedTo)
                            self.sharedInfoItems.append(sharedItem)
                        } else if let _ = sharedTo["name"] {
                            sharedItem.group = ASCGroup(JSON: sharedTo)
                            self.sharedInfoItems.append(sharedItem)
                        }
                    }
                }
            }
            self.presenter?.presentData(response: .presentRightHolders(sharedInfoItems: self.sharedInfoItems, currentUser: self.currentUser))
            
        }
    }
    
    private func makeApiRequest(entity: ASCEntity) -> String? {
        var request: String? = nil
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        return request
    }
    
}
