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
    var sharedInfoItems: [ASCShareInfo] { get }
}

class ASCSharingOptionsInteractor: ASCSharingOptionsBusinessLogic, ASCSharingOptionsDataStore {
    
    var presenter: ASCSharingOptionsPresentationLogic?
    var sharedInfoItems: [ASCShareInfo] = []
    
    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType) {
        switch request {
        
        case .loadRightHolders(entity: let entity):
            guard let entity = entity else {
                presenter?.presentData(response: .presentRightHolders(sharedInfoItems: []))
                return
            }
            
            guard let apiRequest = makeApiRequest(entity: entity) else {
                presenter?.presentData(response: .presentRightHolders(sharedInfoItems: []))
                return
            }

            ASCOnlyOfficeApi.get(apiRequest) { (results, error, response) in
                
                if let results = results as? [[String: Any]] {
                    
                    for item in results {
                        var sharedItem = ASCShareInfo()
                        
                        sharedItem.access = ASCShareAccess(item["access"] as? Int ?? 0)
                        sharedItem.locked = item["isLocked"] as? Bool ?? false
                        sharedItem.owner = item["isOwner"] as? Bool ?? false
                        sharedItem.shareLink = item["sharedItem"] as? String
                    
                        // Link for portal users
                        if let _ = sharedItem.shareLink {
                            continue
                        }
                        
                        if let sharedTo = item["sharedTo"] as? [String: Any] {
                            if let _ = sharedTo["userName"] {
                                // User
                                sharedItem.user = ASCUser(JSON: sharedTo)
                            } else if let _ = sharedTo["name"] {
                                // Group
                                sharedItem.group = ASCGroup(JSON: sharedTo)
                            }
                        }
                        self.sharedInfoItems.append(sharedItem)
                    }
                }
                self.presenter?.presentData(response: .presentRightHolders(sharedInfoItems: self.sharedInfoItems))
                
            }
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
