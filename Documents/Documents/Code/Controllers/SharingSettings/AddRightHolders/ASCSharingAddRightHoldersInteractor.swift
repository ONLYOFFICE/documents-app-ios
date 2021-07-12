//
//  ASCSharingAddRightHoldersInteractor.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersBusinessLogic {
    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType)
}

protocol ASCSharingAddRightHoldersDataStore {
    var sharedInfoItems: [ASCShareInfo] { get set }
    var itemsForSharingAdd: [ASCShareInfo] { get }
    var itemsForSharingRemove: [ASCShareInfo] { get }
    
    var users: [ASCUser] { get }
    var groups: [ASCGroup] { get }
}

class ASCSharingAddRightHoldersInteractor: ASCSharingAddRightHoldersBusinessLogic, ASCSharingAddRightHoldersDataStore {
    
    var sharedInfoItems: [ASCShareInfo] = []
    var itemsForSharingAdd: [ASCShareInfo] = []
    var itemsForSharingRemove: [ASCShareInfo] = []
    
    var users: [ASCUser] = []
    var groups: [ASCGroup] = []
    
    var presenter: ASCSharingAddRightHoldersPresentationLogic?
    
    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType) {
        switch requestType {
        case .loadUsers:
            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiUsers) { (results, error, response) in
                if let results = results as? [[String: Any]] {
                    var users: [ASCUser] = []
                    for item in results {
                        if let user = ASCUser(JSON: item) {
                            users.append(user)
                        }
                    }
                    self.users = users
                    self.presenter?.presentData(responseType: .presentUsers(.init(users: users, sharedEntities: self.sharedInfoItems)))
                }
            }
        case .loadGroups: return
            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiGroups) { (results, error, response) in
                if let results = results as? [[String: Any]] {
                    var groups: [ASCGroup] = []
                    for item in results {
                        if let group = ASCGroup(JSON: item) {
                            groups.append(group)
                        }
                    }
                    self.groups = groups
                    self.presenter?.presentData(responseType: .presentGroups(.init(groups: groups, sharedEntities: self.sharedInfoItems)))
                }
            }
        case .selectViewModel(request: let request):
            let model = request.viewModel
            let itemForSharingRemove = findSharedInfo(byId: model.id, in: itemsForSharingRemove)
            
            guard itemForSharingRemove == nil else {
                remove(shareInfo: itemForSharingRemove!, from: &itemsForSharingRemove)
                return
            }
            
            switch model.rightHolderType {
            case .user:
                if let user = users.first(where: { $0.userId == model.id }) {
                    let shareInfo = ASCShareInfo(access: request.access, user: user)
                    itemsForSharingAdd.append(shareInfo)
                }
            case .group:
                if let group = groups.first(where: { $0.id == model.id }) {
                    let shareInfo = ASCShareInfo(access: request.access, group: group)
                    itemsForSharingAdd.append(shareInfo)
                }
            default: return
            }
        case .deselectViewModel(request: let request):
            let model = request.viewModel
            let sharedInfoItem = findSharedInfo(byId: model.id, in: sharedInfoItems)
            
            guard sharedInfoItem == nil else {
                itemsForSharingRemove.append(sharedInfoItem!)
                return
            }
            
            switch model.rightHolderType {
            case .user:
                itemsForSharingAdd.removeAll { shareInfo in
                    shareInfo.user?.userId == model.id
                }
            case .group:
                itemsForSharingAdd.removeAll { shareInfo in
                    shareInfo.group?.id == model.id
                }
            default: return
            }
        case .clear:
            sharedInfoItems = []
            itemsForSharingAdd = []
            itemsForSharingRemove = []
            users = []
            groups = []
        }
    }
    
    private func findSharedInfo(byId id: String, in store: [ASCShareInfo]) -> ASCShareInfo? {
        var sharedInfo: ASCShareInfo?
        
        for item in store {
            if item.user?.userId == id || item.group?.id == id {
                sharedInfo = item
                break
            }
        }
        
        return sharedInfo
    }
    
    private func remove(shareInfo: ASCShareInfo, from store: inout [ASCShareInfo]) {
        store.removeAll { item in
            item.user?.userId == shareInfo.user?.userId || item.group?.id == shareInfo.group?.id
        }
    }
}
