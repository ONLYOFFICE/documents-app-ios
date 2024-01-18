//
//  ASCSharingAddRightHoldersInteractor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersBusinessLogic {
    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType)
}

class ASCSharingAddRightHoldersInteractor: ASCSharingAddRightHoldersBusinessLogic {
    var dataStore: ASCSharingAddRightHoldersDataStore?
    var presenter: ASCSharingAddRightHoldersPresentationLogic?
    var apiWorker: ASCShareSettingsAPIWorkerProtocol
    var networkingRequestManager: NetworkingRequestingProtocol

    init(apiWorker: ASCShareSettingsAPIWorkerProtocol,
         networkingRequestManager: NetworkingRequestingProtocol)
    {
        self.apiWorker = apiWorker
        self.networkingRequestManager = networkingRequestManager
    }

    func makeRequest(requestType: ASCSharingAddRightHolders.Model.Request.RequestType) {
        switch requestType {
        case let .loadUsers(preloadRightHolders, hideUsersWhoHasRights, showOnlyAdmins):
            guard preloadRightHolders else {
                loadUsers(hideUsersWhoHasRights: hideUsersWhoHasRights, showOnlyAdmins: showOnlyAdmins)
                return
            }
            loadRightHolders { [weak self] in
                self?.loadUsers(hideUsersWhoHasRights: hideUsersWhoHasRights, showOnlyAdmins: showOnlyAdmins)
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
        case let .changeAccessForSelected(request: access):
            var updatedItems = [OnlyofficeShare]()
            dataStore?.itemsForSharingAdd.forEach { item in
                var item = item
                item.access = access
                updatedItems.append(item)
            }
            dataStore?.itemsForSharingAdd = updatedItems

        case let .changeOwner(userId, _: handler):
            changeOwner(userId, handler)
        }
    }

    private func loadUsers(hideUsersWhoHasRights: Bool, showOnlyAdmins: Bool) {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.all) { [unowned self] response, error in
            if let error = error {
                log.error(error)
            } else if let users = response?.result {
                let users = users.filter { user in
                    let isFilteredUser = showOnlyAdmins ? (user.isAdmin || user.isRoomAdmin) : true
                    return isFilteredUser && !(self.dataStore?.sharedInfoItems.contains(where: { $0.user?.userId == user.userId }) ?? false)
                }
                self.dataStore?.users = users
                let sharedInfoItems = self.dataStore?.sharedInfoItems ?? []
                self.presenter?.presentData(responseType: .presentUsers(.init(users: users,
                                                                              sharedEntities: sharedInfoItems,
                                                                              entityOwner: self.dataStore?.entityOwner,
                                                                              currentUser: self.dataStore?.currentUser)))
            }
        }
    }

    private func loadRightHolders(completion: @escaping () -> Void) {
        guard let entity = dataStore?.entity, let apiRequest = apiWorker.makeApiRequest(entity: entity, for: .get) else {
            completion()
            return
        }

        let params = apiWorker.convertToParams(entities: [entity])

        networkingRequestManager.request(apiRequest, params) { [weak self] response, error in
            defer { completion() }
            guard let self = self, error == nil else { return }
            if let sharedItems = response?.result {
                self.dataStore?.sharedInfoItems = sharedItems.filter { $0.user != nil || $0.group != nil }
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

    private func changeOwner(_ userId: String, _ handler: ASCEntityHandler?) {
        handler?(.begin, nil, nil)

        guard let folder = dataStore?.entity as? ASCFolder else {
            handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Invalid folder", comment: "")))
            return
        }
        let access: ASCShareAccess = .none
        let ownerUserId: String = folder.createdBy?.userId ?? ""

        let parameters: [String: Any] = [
            "userId": userId,
            "folderIds": [folder.id],
        ]

        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.invitations = [.init(id: ownerUserId, access: access)]

        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.changeOwner(), parameters) { response, error in
            if error != nil {
                handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Couldn't change the owner.", comment: "")))
                return
            } else {
                OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.inviteRequest(folder: folder), inviteRequestModel.toJSON()) { result, error in
                    if error != nil {
                        handler?(.error, nil, ASCProviderError(msg: NSLocalizedString("Couldn't leave the room", comment: "")))
                    } else {
                        handler?(.end, folder, nil)
                    }
                }
            }
        }
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
