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

class ASCSharingAddRightHoldersInteractor: ASCSharingAddRightHoldersBusinessLogic {
    
    var dataStore: ASCSharingAddRightHoldersDataStore?
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
                    self.dataStore?.users = users
                    let sharedInfoItems = self.dataStore?.sharedInfoItems ?? []
                    self.presenter?.presentData(responseType: .presentUsers(.init(users: users, sharedEntities: sharedInfoItems)))
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
                    self.dataStore?.groups = groups
                    let sharedInfoItems = self.dataStore?.sharedInfoItems ?? []
                    self.presenter?.presentData(responseType: .presentGroups(.init(groups: groups, sharedEntities: sharedInfoItems)))
                }
            }
        case .selectViewModel(request: let request):
            if let shareInfo = makeShareInfo(model: request.selectedViewModel, access: request.access) {
                dataStore?.add(shareInfo: shareInfo)
            }
            if let type = defineType(byId: request.selectedViewModel.id) {
                presenter?.presentData(responseType: .presentSelected(.init(selectedModel: request.selectedViewModel, isSelect: true, type: type)))
            }
        case .deselectViewModel(request: let request):
            if let shareInfo = makeShareInfo(model: request.deselectedViewModel, access: .none) {
                dataStore?.remove(shareInfo: shareInfo)
            }
            if let type = defineType(byId: request.deselectedViewModel.id) {
                presenter?.presentData(responseType: .presentSelected(.init(selectedModel: request.deselectedViewModel, isSelect: false, type: type)))
            }
        }
    }
    
    private func makeShareInfo(model: ASCSharingRightHolderViewModel, access: ASCShareAccess) -> ASCShareInfo? {
        guard let dataStore = dataStore else { return nil }
        switch model.rightHolderType {
        case .user:
            if let user = dataStore.users.first(where: { $0.userId == model.id }) {
                return ASCShareInfo(access: access, user: user)
            }
        case .group:
            if let group = dataStore.groups.first(where: { $0.id == model.id }) {
                return ASCShareInfo(access: access, group: group)
            }
        default: return nil
        }
        return nil
    }
    
    private func defineType(byId id: String) -> RightHoldersTableType? {
        guard let dataStore = dataStore else { return nil }
        if let _ = dataStore.users.firstIndex(where: { $0.userId == id }) {
            return .users
        } else if let _ = dataStore.groups.firstIndex(where: { $0.id == id }) {
            return .groups
        }
        return nil
    }
}
