//
//  OnlyofficeShare.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

struct OnlyofficeShare: Mappable {
    
    var access: ASCShareAccess = .none
    var sharedTo: [String : Any]?
    var locked: Bool = false
    var owner: Bool = false
    
    private var innerUser: ASCUser?
    private var innerGroup: ASCGroup?
    
    var user: ASCUser? {
        guard innerUser == nil else { return innerUser }
        
        guard
            let sharedTo = sharedTo,
            link == nil,                 // Mark if not link
            let _ = sharedTo["userName"] // Mark if user share
        else { return nil }
        
        return ASCUser(JSON: sharedTo)
    }
    
    var group: ASCGroup? {
        guard innerGroup == nil else { return innerGroup }
        
        guard
            let sharedTo = sharedTo,
            link == nil,                // Mark if not link
            sharedTo["userName"] == nil // Mark if group share
        else { return nil }
        
        return ASCGroup(JSON: sharedTo)
    }
    
    var link: String? {
        guard
            let sharedTo = sharedTo
        else { return nil }
        
        return sharedTo["shareLink"] as? String
    }
    
    private mutating func setInnerUser(user: ASCUser) {
        
    }
    
    init(access: ASCShareAccess, user: ASCUser) {
        self.access = access
        self.innerUser = user
    }
    
    init(access: ASCShareAccess, group: ASCGroup) {
        self.access = access
        self.innerGroup = group
    }
    
    init() {
        
    }
    
    init?(map: Map) {
        
    }

    mutating func mapping(map: Map) {
        access      <- (map["access"], EnumTransform())
        sharedTo    <- map["sharedTo"]
        locked      <- map["isLocked"]
        owner       <- map["isOwner"]
    }
}
