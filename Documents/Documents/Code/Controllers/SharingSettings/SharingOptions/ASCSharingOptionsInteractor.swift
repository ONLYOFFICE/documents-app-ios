//
//  ASCSharingOptionsInteractor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import MBProgressHUD
import UIKit

protocol ASCSharingOptionsBusinessLogic {
    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType)
}

protocol ASCSharingOptionsDataStore {
    var entity: ASCEntity? { get }
    var entityOwner: ASCUser? { get }
    var currentUser: ASCUser? { get }
    var sharedInfoItems: [OnlyofficeShare] { get }
}

class ASCSharingOptionsInteractor: ASCSharingOptionsBusinessLogic, ASCSharingOptionsDataStore {
    // MARK: - Workers

    let entityLinkMaker: ASCEntityLinkMakerProtocol

    // MARK: - ASCSharingOptionsDataStore properties

    var entity: ASCEntity?
    var entityOwner: ASCUser?
    var currentUser: ASCUser?
    var sharedInfoItems: [OnlyofficeShare] = []

    // MARK: - ASCSharingOptionsBusinessLogic

    var presenter: ASCSharingOptionsPresentationLogic?
    let apiWorker: ASCShareSettingsAPIWorkerProtocol
    var networkingRequestManager: NetworkingRequestingProtocol

    init(entityLinkMaker: ASCEntityLinkMakerProtocol, entity: ASCEntity, apiWorker: ASCShareSettingsAPIWorkerProtocol, networkingRequestManager: NetworkingRequestingProtocol) {
        self.entityLinkMaker = entityLinkMaker
        self.entity = entity
        self.apiWorker = apiWorker
        self.networkingRequestManager = networkingRequestManager
    }

    func makeRequest(request: ASCSharingOptions.Model.Request.RequestType) {
        switch request {
        case let .loadRightHolders(loadRightHoldersRequest: loadRightHoldersRequest):
            loadCurrentUser()
            loadRightHolders(loadRightHoldersRequest: loadRightHoldersRequest)
        case let .changeRightHolderAccess(changeRightHolderAccessRequest: changeRightHolderAccessRequest):
            changeRightHolderAccess(changeRightHolderAccessRequest: changeRightHolderAccessRequest)
        case .clearData:
            currentUser = nil
            sharedInfoItems = []
        case let .removeRightHolderAccess(removeRightHolderRequest: removeRightHolderRequest):
            removeRightHolderAccess(removeRightHolderAccessRequest: removeRightHolderRequest)
        }
    }

    private func loadCurrentUser() {
        currentUser = ASCFileManager.onlyofficeProvider?.user
    }

    private func loadRightHolders(loadRightHoldersRequest: ASCSharingOptions.Model.Request.LoadRightHoldersRequest) {
        guard let entity = loadRightHoldersRequest.entity
        else {
            presenter?.presentData(response: .presentRightHolders(.failure(NetworkingError.unknown(error: nil))))
            return
        }

        let internalLink = entityLinkMaker.make(entity: entity)

        guard let apiRequest = apiWorker.makeApiRequest(entity: entity, for: .get)
        else {
            presenter?.presentData(response: .presentRightHolders(.failure(NetworkingError.unknown(error: nil))))
            return
        }

        let params = apiWorker.convertToParams(entities: [entity])

        networkingRequestManager.request(apiRequest, params) { [weak self] response, error in
            guard let self = self else { return }
            var exteralLink: ASCSharingOprionsExternalLink?
            guard error == nil else {
                self.presenter?.presentData(response: .presentRightHolders(.failure(error!)))
                return
            }
            if let sharedItems = response?.result {
                self.sharedInfoItems = sharedItems.filter { $0.user != nil || $0.group != nil }
                if let linkItem = sharedItems.first(where: { $0.link != nil }),
                   let link = linkItem.link,
                   let shareId = linkItem.sharedTo?["id"] as? String
                {
                    exteralLink = .init(id: shareId, link: link, isLocked: linkItem.locked, access: linkItem.access)
                }
            }

            self.presenter?.presentData(response: .presentRightHolders(.success(.init(sharedInfoItems: self.sharedInfoItems,
                                                                                      currentUser: self.currentUser,
                                                                                      internalLink: internalLink,
                                                                                      externalLink: exteralLink))))
        }
    }

    private func changeRightHolderAccess(changeRightHolderAccessRequest: ASCSharingOptions.Model.Request.ChangeRightHolderAccessRequest) {
        let entity = changeRightHolderAccessRequest.entity
        var rightHolder = changeRightHolderAccessRequest.rightHolder
        let access = changeRightHolderAccessRequest.access

        guard let request = apiWorker.makeApiRequest(entity: entity, for: .set) else { return }

        let json = makeJsonParams(entity: entity, rightHolder: rightHolder, access: access)

        networkingRequestManager.request(request, json) { [weak self] _, error in
            if error == nil {
                rightHolder.access = access
                if let index = self?.sharedInfoItems.firstIndex(where: { $0.user?.userId == rightHolder.id || $0.group?.id == rightHolder.id }) {
                    self?.sharedInfoItems[index].access = access
                }
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(.init(rightHolder: rightHolder, error: nil)))
            } else {
                let errorMessage = error?.localizedDescription
                self?.presenter?.presentData(response: .presentChangeRightHolderAccess(.init(rightHolder: rightHolder, error: errorMessage)))
            }
        }
    }

    private func removeRightHolderAccess(removeRightHolderAccessRequest: ASCSharingOptions.Model.Request.RemoveRightHolderAccessRequest) {
        let entity = removeRightHolderAccessRequest.entity
        let rightHolder = removeRightHolderAccessRequest.rightHolder

        guard let sharedItemIndex = sharedInfoItems.firstIndex(where: { $0.user?.userId == rightHolder.id || $0.group?.id == rightHolder.id }) else { return }
        let sharedItem = sharedInfoItems[sharedItemIndex]
        guard !sharedItem.locked else { return }

        guard let request = apiWorker.makeApiRequest(entity: entity, for: .set) else { return }

        let json = makeJsonParams(entity: entity, rightHolder: rightHolder, access: .none)
        networkingRequestManager.request(request, json) { [weak self] _, error in
            if error == nil {
                self?.sharedInfoItems.remove(at: sharedItemIndex)
                self?.presenter?.presentData(response: .presentRemoveRightHolderAccess(.init(indexPath: removeRightHolderAccessRequest.indexPath,
                                                                                             rightHolder: rightHolder,
                                                                                             rightHolderShareInfo: sharedItem,
                                                                                             error: nil)))
            } else {
                let errorMessage = error?.localizedDescription
                self?.presenter?.presentData(response: .presentRemoveRightHolderAccess(.init(indexPath: removeRightHolderAccessRequest.indexPath,
                                                                                             rightHolder: rightHolder,
                                                                                             rightHolderShareInfo: sharedItem,
                                                                                             error: errorMessage)))
            }
        }
    }

    private func makeJsonParams(entity: ASCEntity, rightHolder: ASCSharingRightHolder, access: ASCShareAccess) -> [String: Any] {
        guard entity.isRoom else {
            let shareRequestModel = OnlyofficeShareRequestModel()
            shareRequestModel.notify = false
            shareRequestModel.share = apiWorker.convertToParams(items: [(rightHolder.id, access)])
            return shareRequestModel.toJSON()
        }
        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.invitations = [.init(id: rightHolder.id, access: access)]
        return inviteRequestModel.toJSON()
    }
}
