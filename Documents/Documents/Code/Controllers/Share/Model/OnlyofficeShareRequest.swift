//
//  OnlyofficeShareRequest.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeShareItemRequest: Mappable {
    var shareTo: String?
    var access: ASCShareAccess = .none
    
    init() { }
    
    convenience init(shareTo: String, access: ASCShareAccess) {
        self.init()
        
        self.shareTo = shareTo
        self.access = access
    }
    
    required init?(map: Map) { }

    func mapping(map: Map) {
        shareTo <- map["shareTo"]
        access  <- (map["access"], EnumTransform())
        
    }
}
    
class OnlyofficeShareRequest: Mappable {
    var notify: Bool = false
    var sharingMessage: String?
    var share: [OnlyofficeShareItemRequest]?
    
    init() { }
    
    required init?(map: Map) { }

    func mapping(map: Map) {
        notify          <- map["notify"]
        sharingMessage  <- map["sharingMessage"]
        share           <- map["share"]
        
    }
}
