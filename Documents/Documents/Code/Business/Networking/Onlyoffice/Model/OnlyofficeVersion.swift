//
//  OnlyofficeVersion.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeVersion: Mappable {
    var community: String?
    var document: String?
    var mail: String?
    var xmpp: String?

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        community   <- map["communityServer"]
        document    <- map["documentServer"]
        mail        <- map["mailServer"]
        xmpp        <- map["xmppServer"]
        community   <- map["communityServer"]
    }
}
