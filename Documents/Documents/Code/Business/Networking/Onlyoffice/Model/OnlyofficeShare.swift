//
//  OnlyofficeShare.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeShare: Mappable {
    var access: ASCShareAccess = .none
    var sharedTo: [String : Any]?
    var locked: Bool = false
    var owner: Bool = false
    
    var user: ASCUser? {
        guard
            let sharedTo = sharedTo,
            link == nil,                 // Mark if not link
            let _ = sharedTo["userName"] // Mark if user share
        else { return nil }
        
        return ASCUser(JSON: sharedTo)
    }
    
    var group: ASCGroup? {
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
    
    init() {
        //
    }
    
    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        access      <- (map["access"], EnumTransform())
        sharedTo    <- map["sharedTo"]
        locked      <- map["isLocked"]
        owner       <- map["isOwner"]
    }
}
