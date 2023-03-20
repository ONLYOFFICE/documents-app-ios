//
//  ASCSharingAddRightHoldersRAMDataStore.swift
//  Documents
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingAddRightHoldersBaseDataStore {
    var entity: ASCEntity? { get set }
    var entityOwner: ASCUser? { get set }
    var currentUser: ASCUser? { get set }
    var doneCompletion: () -> Void { get set }

    var sharedInfoItems: [OnlyofficeShare] { get set }
    var itemsForSharingAdd: [OnlyofficeShare] { get set }
    var itemsForSharingRemove: [OnlyofficeShare] { get set }
    var users: [ASCUser] { get set }

    func add(shareInfo: OnlyofficeShare)
    func remove(shareInfo: OnlyofficeShare)

    func clear()
}

protocol ASCSharingAddRightHoldersDataStore: ASCSharingAddRightHoldersBaseDataStore {
    var groups: [ASCGroup] { get set }
}

class ASCSharingAddRightHoldersBaseRAMDataStore: ASCSharingAddRightHoldersBaseDataStore {
    var entity: ASCEntity?
    var entityOwner: ASCUser?
    var currentUser: ASCUser?
    var doneCompletion: () -> Void = {}

    var sharedInfoItems: [OnlyofficeShare] = []
    var itemsForSharingAdd: [OnlyofficeShare] = []
    var itemsForSharingRemove: [OnlyofficeShare] = []

    var users: [ASCUser] = []

    /// add to itemsForSharingAdd if do not exist in sharedInfoItems and remove from itemsForSharingRemove if exist there
    func add(shareInfo: OnlyofficeShare) {
        if findShareInfo(byShareInfo: shareInfo, in: itemsForSharingRemove) != nil {
            remove(shareInfo: shareInfo, from: &itemsForSharingRemove)
        }

        guard findShareInfo(byShareInfo: shareInfo, in: sharedInfoItems) == nil else {
            return
        }

        itemsForSharingAdd.append(shareInfo)
    }

    /// add to itemsForSharingRemove if exist in itemsForSharingAdd  and remove from itemsForSharingAdd if exist there
    func remove(shareInfo: OnlyofficeShare) {
        if findShareInfo(byShareInfo: shareInfo, in: itemsForSharingAdd) != nil {
            remove(shareInfo: shareInfo, from: &itemsForSharingAdd)
        }

        guard var sharedInfoItem = findShareInfo(byShareInfo: shareInfo, in: sharedInfoItems) else {
            return
        }

        sharedInfoItem.access = .none
        itemsForSharingRemove.append(sharedInfoItem)
    }

    func clear() {
        sharedInfoItems = []
        itemsForSharingAdd = []
        itemsForSharingRemove = []
        users = []
    }

    private func findShareInfo(byShareInfo shareInfo: OnlyofficeShare, in store: [OnlyofficeShare]) -> OnlyofficeShare? {
        var sharedInfo: OnlyofficeShare?

        guard let entityId: String = shareInfo.user?.userId ?? shareInfo.group?.id else { return nil }

        for item in store {
            if item.user?.userId == entityId || item.group?.id == entityId {
                sharedInfo = item
                break
            }
        }

        return sharedInfo
    }

    private func remove(shareInfo: OnlyofficeShare, from store: inout [OnlyofficeShare]) {
        guard let entityId: String = shareInfo.user?.userId ?? shareInfo.group?.id else { return }

        store.removeAll { item in
            item.user?.userId == entityId || item.group?.id == entityId
        }
    }
}

class ASCSharingAddRightHoldersRAMDataStore: ASCSharingAddRightHoldersBaseRAMDataStore, ASCSharingAddRightHoldersDataStore {
    var groups: [ASCGroup] = []

    override func clear() {
        super.clear()
        groups = []
    }
}
