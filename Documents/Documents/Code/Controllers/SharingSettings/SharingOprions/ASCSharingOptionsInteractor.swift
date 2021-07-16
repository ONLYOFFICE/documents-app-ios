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
    var entity: ASCEntity? { get }
    var currentUser: ASCUser? { get }
    var sharedInfoItems: [ASCShareInfo] { get }
}

class ASCSharingOptionsInteractor: ASCSharingOptionsBusinessLogic, ASCSharingOptionsDataStore {
    // MARK: - Workers
    let entityLinkMaker: ASCEntityLinkMakerProtocol
    
    // MARK: - ASCSharingOptionsDataStore properties
    var entity: ASCEntity?
    var currentUser: ASCUser?
    var sharedInfoItems: [ASCShareInfo] = []
    
    // MARK: - ASCSharingOptionsBusinessLogic
    var presenter: ASCSharingOptionsPresentationLogic?
    
    init(entityLinkMaker: ASCEntityLinkMakerProtocol, entity: ASCEntity) {
        self.entityLinkMaker = entityLinkMaker
        self.entity = entity
    }
    
    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType) {
        switch request {
        case .loadRightHolders(loadRightHoldersRequest: let loadRightHoldersRequest):
            loadCurrentUser()
            loadRightHolders(loadRightHoldersRequest: loadRightHoldersRequest)
        case .changeRightHolderAccess(changeRightHolderAccessRequest: let changeRightHolderAccessRequest):
            changeRightHolderAccess(changeRightHolderAccessRequest: changeRightHolderAccessRequest)
        case .clearData:
            currentUser = nil
            sharedInfoItems = []
        }
    }
    
    private func loadCurrentUser() {
        currentUser = ASCFileManager.onlyofficeProvider?.user
    }
    
    private func loadRightHolders(loadRightHoldersRequest: ASCSharingOptions.Model.Request.LoadRightHoldersRequest) {

        guard let entity = loadRightHoldersRequest.entity
        else {
            presenter?.presentData(response: .presentRightHolders(
                                    .init(sharedInfoItems: [], currentUser: currentUser, internalLink: nil, externalLink: nil)))
            return
        }
        
        let internalLink = entityLinkMaker.make(entity: entity)
        
        guard let apiRequest = makeApiRequest(entity: entity)
        else {
            presenter?.presentData(response: .presentRightHolders(
                                    .init(sharedInfoItems: [], currentUser: currentUser, internalLink: internalLink, externalLink: nil)))
            return
        }

        ASCOnlyOfficeApi.get(apiRequest) { (results, error, response) in
            var exteralLink: ASCSharingOprionsExternalLink?
            if let results = results as? [[String: Any]] {
                self.sharedInfoItems = []
                for item in results {
                    var sharedItem = ASCShareInfo()
                    
                    sharedItem.access = ASCShareAccess(item["access"] as? Int ?? 0)
                    sharedItem.locked = item["isLocked"] as? Bool ?? false
                    sharedItem.owner = item["isOwner"] as? Bool ?? false

                    if let sharedTo = item["sharedTo"] as? [String: Any] {
                        
                        /// External link
                        let shareLink = sharedTo["shareLink"] as? String
                        let shareId = sharedTo["id"] as? String
                        if shareLink != nil && shareId != nil {
                            exteralLink = .init(id: shareId!, link: shareLink!, isLocked: sharedItem.locked, access: sharedItem.access)
                            continue
                        }
                        
                        if let _ = sharedTo["userName"] {
                            sharedItem.user = ASCUser(JSON: sharedTo)
                        } else if let _ = sharedTo["name"] {
                            sharedItem.group = ASCGroup(JSON: sharedTo)
                        }
                        self.sharedInfoItems.append(sharedItem)
                    }
                }
            }
            
            self.presenter?.presentData(response: .presentRightHolders(.init(sharedInfoItems: self.sharedInfoItems,
                                                                             currentUser: self.currentUser,
                                                                             internalLink: internalLink,
                                                                             externalLink: exteralLink)))
        }
    }
    
    private func changeRightHolderAccess(changeRightHolderAccessRequest: ASCSharingOptions.Model.Request.ChangeRightHolderAccessRequest) {
        var shares: [[String: Any]] = []
        var request: String!
        
        let entity = changeRightHolderAccessRequest.entity
        var rightHolder = changeRightHolderAccessRequest.rightHolder
        let access = changeRightHolderAccessRequest.access
        
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
                rightHolder.access = access
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(.init(rightHolder: rightHolder, error: nil)))
            } else if let response = response {
                let errorMessage = ASCOnlyOfficeApi.errorMessage(by: response)
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(.init(rightHolder: rightHolder, error: errorMessage)))
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
