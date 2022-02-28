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
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.all) { [unowned self] response, error in

                if let error = error {
                    log.error(error)
                } else if let users = response?.result {
                    self.dataStore?.users = users
                    self.dataStore?.users = users
                    let sharedInfoItems = self.dataStore?.sharedInfoItems ?? []
                    self.presenter?.presentData(responseType: .presentUsers(.init(users: users,
                                                                                  sharedEntities: sharedInfoItems,
                                                                                  entityOwner: self.dataStore?.entityOwner,
                                                                                  currentUser: self.dataStore?.currentUser)))
                }
            }
        case .loadGroups: return
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.groups) { [unowned self] response, error in
                if let error = error {
                    log.error(error)
                } else if let groups = response?.result {
                    self.dataStore?.groups = groups
                    let sharedInfoItems = self.dataStore?.sharedInfoItems ?? []
                    self.presenter?.presentData(responseType: .presentGroups(.init(groups: groups, sharedEntities: sharedInfoItems)))
                }
            }
        case let .selectViewModel(request: request):
            if let shareInfo = makeShareInfo(model: request.selectedViewModel, access: request.access) {
                dataStore?.add(shareInfo: shareInfo)
            }
            if let type = defineType(byId: request.selectedViewModel.id) {
                presenter?.presentData(responseType: .presentSelected(.init(selectedModel: request.selectedViewModel, isSelect: true, type: type)))
            }
        case let .deselectViewModel(request: request):
            if let shareInfo = makeShareInfo(model: request.deselectedViewModel, access: .none) {
                dataStore?.remove(shareInfo: shareInfo)
            }
            if let type = defineType(byId: request.deselectedViewModel.id) {
                presenter?.presentData(responseType: .presentSelected(.init(selectedModel: request.deselectedViewModel, isSelect: false, type: type)))
            }
        }
    }

    private func makeShareInfo(model: ASCSharingRightHolderViewModel, access: ASCShareAccess) -> OnlyofficeShare? {
        guard let dataStore = dataStore else { return nil }
        switch model.rightHolderType {
        case .user:
            if let user = dataStore.users.first(where: { $0.userId == model.id }) {
                return OnlyofficeShare(access: access, user: user)
            }
        case .group:
            if let group = dataStore.groups.first(where: { $0.id == model.id }) {
                return OnlyofficeShare(access: access, group: group)
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
