//
//  ASCSharingSettingsVerifyRightHoldersInteractor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

protocol ASCSharingSettingsVerifyRightHoldersBusinessLogic {
    func makeRequest(requestType: ASCSharingSettingsVerifyRightHolders.Model.Request.RequestType)
}

protocol ASCSharingSettingsVerifyRightHoldersDataStore {
    var entity: ASCEntity? { get set }
    var doneComplerion: () -> Void { get set }
    
    var sharedInfoItems: [ASCShareInfo] { get set }
    var itemsForSharingAdd: [ASCShareInfo] { get set }
    var itemsForSharingRemove: [ASCShareInfo] { get set }
    var itemsForSharedAccessChange: [ASCShareInfo] { get }
    
    func clearData() -> Void
}

class ASCSharingSettingsVerifyRightHoldersInteractor: ASCSharingSettingsVerifyRightHoldersBusinessLogic, ASCSharingSettingsVerifyRightHoldersDataStore {
    
    // MARK: - Data source vars
    var entity: ASCEntity? {
        didSet {
            guard let entity = entity else { return }
            accessProvider = ASCSharingSettingsAccessProviderFactory().get(entity: entity, isAccessExternal: false)
        }
    }
    var doneComplerion: () -> Void = {}
    
    
    var sharedInfoItems: [ASCShareInfo] = []
    var itemsForSharingAdd: [ASCShareInfo] = []
    
    /// property for remove shared items
    var itemsForSharingRemove: [ASCShareInfo] = []
    
    /// property for changing access in shared items
    private(set) var itemsForSharedAccessChange: [ASCShareInfo] = []
    
    // MARK: - other vars
    private var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsAccessDefaultProvider()
    
    var presenter: ASCSharingSettingsVerifyRightHoldersPresentationLogic?
    let apiWorker: ASCShareSettingsAPIWorkerProtocol
    
    init(apiWorker: ASCShareSettingsAPIWorkerProtocol) {
        self.apiWorker = apiWorker
    }
    
    func clearData() {
        entity = nil
        doneComplerion = {}
        sharedInfoItems = []
        itemsForSharingAdd = []
        itemsForSharingRemove = []
        itemsForSharedAccessChange = []
    }
    
    func makeRequest(requestType: ASCSharingSettingsVerifyRightHolders.Model.Request.RequestType) {
        switch requestType {
            
        case .loadShareItems:
            let removingGroupsIds = itemsForSharingRemove.map({ $0.group?.id }).compactMap({ $0 })
            let removingUserIds = itemsForSharingRemove.map({ $0.user?.userId }).compactMap({ $0 })
            
            let sharedItemWithoutRemoveItems = sharedInfoItems.filter({
                if let userId = $0.user?.userId {
                    return !removingUserIds.contains(userId)
                } else if let groupId = $0.group?.id {
                    return !removingGroupsIds.contains(groupId)
                }
                return true
            })
            let items = sharedItemWithoutRemoveItems + itemsForSharingAdd
            presenter?.presentData(responseType: .presentShareItems(.init(items: items)))
        case .loadAccessProvider:
            presenter?.presentData(responseType: .presentAccessProvider(accessProvider))
        case .applyShareSettings(requst: let request):
            guard let entity = entity else {
                log.error("Couldn't get an entity for aplly sharing settings")
                presenter?.presentData(responseType: .presentApplyingShareSettings(.init(error: NSLocalizedString("Something wrong", comment: ""))))
                return
            }
            
            guard let apiRequest: String = apiWorker.makeApiRequest(entity: entity) else {
                log.error("Couldn't make an api request on entity")
                presenter?.presentData(responseType: .presentApplyingShareSettings(.init(error: NSLocalizedString("Something wrong", comment: ""))))
                return
            }
            
            let baseParams: Parameters = [
                "notify": request.notify ? "true" : "false",
                "sharingMessage": request.notifyMessage ?? ""
            ]
            
            let itemsForRequest = (itemsForSharingAdd + itemsForSharingRemove + itemsForSharedAccessChange).filter({ !$0.locked })
            let sharesParams = apiWorker.convertToParams(shareItems: itemsForRequest)
            
            ASCOnlyOfficeApi.put(apiRequest, parameters: baseParams + sharesParams) { [weak self] (results, error, response) in
                if let _ = results as? [[String: Any]] {
                    self?.presenter?.presentData(responseType: .presentApplyingShareSettings(.init()))
                } else if let response = response, let self = self {
                    let errorMessage = ASCOnlyOfficeApi.errorMessage(by: response)
                    log.error(errorMessage)
                    self.presenter?.presentData(responseType: .presentApplyingShareSettings(.init(error: errorMessage)))
                } else {
                    log.error("unexpected conditional branching")
                    self?.presenter?.presentData(responseType: .presentApplyingShareSettings(.init(error: NSLocalizedString("Something wrong", comment: ""))))
                }
            }
            
        case .accessChange(request: let request):
            var model = request.model
            let successUpdate = update(access: request.newAccess, byModel: model)
            
            if successUpdate {
                model.access?.entityAccess = request.newAccess
            }
            
            presenter?.presentData(responseType: .presentAccessChange(.init(model: model, errorMessage: successUpdate ? nil : NSLocalizedString("Something wrong", comment: ""))))
        case .accessRemove(request: let request):
            let successUpdate = update(access: .none, byModel: request.model)
            let errorMessage = successUpdate ? nil : NSLocalizedString("Something wrong", comment: "")
            presenter?.presentData(responseType: .presentAccessRemove(.init(indexPath: request.indexPath, errorMessage: errorMessage)))
        }
    }
    
    private func update(access: ASCShareAccess, byModel model: ASCSharingRightHolderViewModel) -> Bool {
        guard model.access?.accessEditable == true else {
            return false
        }
        
        if isItemAlreadyShared(itemId: model.id),
           var sharedItem = getItem(byId: model.id, in: sharedInfoItems)
        {
            /// If the access has changed to the original - remove from itemsForShringChange
            guard sharedItem.access != access else {
                let _ = deleteIfExistShareItem(byId: model.id, from: &itemsForSharedAccessChange)
                return true
            }
            
            /// change if exist otherwise add
            if let changingSharedItemIndex = getItemIndex(byId: model.id, in: itemsForSharedAccessChange) {
                if access == .none {
                    itemsForSharedAccessChange.remove(at: changingSharedItemIndex)
                } else {
                    itemsForSharedAccessChange[changingSharedItemIndex].access = access
                }
            } else if access != .none {
                sharedItem.access = access
                itemsForSharedAccessChange.append(sharedItem)
            }
            
            if access == .none {
                sharedItem.access = access
                itemsForSharingRemove.append(sharedItem)
            }
            
            return true
        } else if let index = getItemIndex(byId: model.id, in: itemsForSharingAdd) {
            if access == .none {
                itemsForSharingAdd.remove(at: index)
            } else {
                itemsForSharingAdd[index].access = access
            }
            return true
        }
        return false
    }
    
    private func isItemAlreadyShared(itemId id: String) -> Bool {
        return getItemIndex(byId: id, in: sharedInfoItems) != nil
    }
    
    private func deleteIfExistShareItem(byId id: String, from items: inout [ASCShareInfo]) -> Bool {
        if let index = getItemIndex(byId: id, in: items) {
            items.remove(at: index)
        }
        return false
    }
    
    private func getItem(byId id: String, in items: [ASCShareInfo]) -> ASCShareInfo? {
        guard let index = getItemIndex(byId: id, in: items) else { return nil }
        return items[index]
    }
    
    private func getItemIndex(byId id: String, in items: [ASCShareInfo]) -> Int? {
        items.firstIndex(where: { $0.user?.userId == id || $0.group?.id == id })
    }
}
