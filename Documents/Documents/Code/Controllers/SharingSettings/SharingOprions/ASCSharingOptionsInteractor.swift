//
//  ASCSharingOptionsInteractor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD

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
        case .changeRightHolderAccess(entity: let entity, rightHolder: let rightHolder, access: let access):
            changeRightHolderAccess(entity: entity, rightHolder: rightHolder, access: access)
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
    
    private func changeRightHolderAccess(entity: ASCEntity, rightHolder: ASCSharingRightHolderViewModel, access: ASCShareAccess) {
        var shares: [[String: Any]] = []
        var request: String!
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        shares.append([
            "ShareTo": rightHolder.id,
            "Access": access.rawValue
        ])
        
        let baseParams: Parameters = [
            "notify": "false"
        ]
        let sharesParams = sharesToParams(shares: shares)
        
        ASCOnlyOfficeApi.put(request, parameters: baseParams + sharesParams) { [weak self] (results, error, response) in
            if let _ = results as? [[String: Any]] {
                var changingRightHolder = rightHolder
                changingRightHolder.access?.documetAccess = access
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(rightHolder: changingRightHolder, error: nil))
            } else if let response = response {
                let errorMessage = ASCOnlyOfficeApi.errorMessage(by: response)
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(rightHolder: rightHolder, error: errorMessage))
            }
        }
    }
    
    private func sharesToParams(shares: [[String: Any]]) -> [String: Any] {
        var params: [String: Any] = [:]
        
        for (index, dictinory) in shares.enumerated() {
            for (key, value) in dictinory {
                params["share[\(index)].\(key)"] = value
            }
        }

        return params
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
