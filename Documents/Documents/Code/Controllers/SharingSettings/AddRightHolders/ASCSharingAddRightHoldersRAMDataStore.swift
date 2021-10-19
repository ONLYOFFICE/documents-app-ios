//
//  ASCSharingAddRightHoldersRAMDataStore.swift
//  Documents
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingAddRightHoldersDataStore {
    var entity: ASCEntity? { get set }
    var entityOwner: ASCUser? { get set }
    var currentUser: ASCUser? { get set }
    var doneComplerion: () -> Void { get set }
    
    var sharedInfoItems: [OnlyofficeShare] { get set }
    var itemsForSharingAdd: [OnlyofficeShare] { get }
    var itemsForSharingRemove: [OnlyofficeShare] { get }
    var users: [ASCUser] { get set }
    var groups: [ASCGroup] { get set }
    
    func add(shareInfo: OnlyofficeShare)
    func remove(shareInfo: OnlyofficeShare)
    
    func clear()
}

class ASCSharingAddRightHoldersRAMDataStore: ASCSharingAddRightHoldersDataStore {
    
    var entity: ASCEntity?
    var entityOwner: ASCUser?
    var currentUser: ASCUser?
    var doneComplerion: () -> Void = {}
    
    var sharedInfoItems: [OnlyofficeShare] = []
    private(set) var itemsForSharingAdd: [OnlyofficeShare] = []
    private(set) var itemsForSharingRemove: [OnlyofficeShare] = []
    
    var users: [ASCUser] = []
    var groups: [ASCGroup] = []
    
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
        groups = []
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