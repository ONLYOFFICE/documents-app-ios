//
//  ASCSharingAddRightHoldersRAMDataStore.swift
//  Documents
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingAddRightHoldersDataStore {
    var currentUser: ASCUser? { get set }
    var entity: ASCEntity? { get set }
    
    var sharedInfoItems: [ASCShareInfo] { get set }
    var itemsForSharingAdd: [ASCShareInfo] { get }
    var itemsForSharingRemove: [ASCShareInfo] { get }
    var users: [ASCUser] { get set }
    var groups: [ASCGroup] { get set }
    
    func add(shareInfo: ASCShareInfo)
    func remove(shareInfo: ASCShareInfo)
    
    func clear()
}

class ASCSharingAddRightHoldersRAMDataStore: ASCSharingAddRightHoldersDataStore {
    var entity: ASCEntity?
    var currentUser: ASCUser?
    
    var sharedInfoItems: [ASCShareInfo] = []
    private(set) var itemsForSharingAdd: [ASCShareInfo] = []
    private(set) var itemsForSharingRemove: [ASCShareInfo] = []
    
    var users: [ASCUser] = []
    var groups: [ASCGroup] = []
    
    /// add to itemsForSharingAdd if do not exist in sharedInfoItems and remove from itemsForSharingRemove if exist there
    func add(shareInfo: ASCShareInfo) {
        
        if findShareInfo(byShareInfo: shareInfo, in: itemsForSharingRemove) != nil {
            remove(shareInfo: shareInfo, from: &itemsForSharingRemove)
        }
        
        guard findShareInfo(byShareInfo: shareInfo, in: sharedInfoItems) == nil else {
            return
        }
        
        itemsForSharingAdd.append(shareInfo)
    }
    
    /// add to itemsForSharingRemove if exist in itemsForSharingAdd  and remove from itemsForSharingAdd if exist there
    func remove(shareInfo: ASCShareInfo) {
        
        if findShareInfo(byShareInfo: shareInfo, in: itemsForSharingAdd) != nil {
            remove(shareInfo: shareInfo, from: &itemsForSharingAdd)
        }
        
        guard let sharedInfoItem = findShareInfo(byShareInfo: shareInfo, in: sharedInfoItems) else {
            return
        }
        
        itemsForSharingRemove.append(sharedInfoItem)
    }
    
    func clear() {
        sharedInfoItems = []
        itemsForSharingAdd = []
        itemsForSharingRemove = []
        users = []
        groups = []
    }
    
    private func findShareInfo(byShareInfo shareInfo: ASCShareInfo, in store: [ASCShareInfo]) -> ASCShareInfo? {
        var sharedInfo: ASCShareInfo?
        
        guard let entityId: String = shareInfo.user?.userId ?? shareInfo.group?.id else { return nil }
        
        for item in store {
            if item.user?.userId == entityId || item.group?.id == entityId {
                sharedInfo = item
                break
            }
        }
        
        return sharedInfo
    }
    
    private func remove(shareInfo: ASCShareInfo, from store: inout [ASCShareInfo]) {
        guard let entityId: String = shareInfo.user?.userId ?? shareInfo.group?.id else { return }
        
        store.removeAll { item in
            item.user?.userId == entityId || item.group?.id == entityId
        }
    }
}
