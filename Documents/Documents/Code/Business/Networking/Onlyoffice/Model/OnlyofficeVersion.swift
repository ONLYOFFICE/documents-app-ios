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
    var docSpace: String?
    var community: String?
    var document: String?
    var mail: String?
    var xmpp: String?

    init() {}

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        docSpace <- map["docSpace"]
        community <- map["communityServer"]
        document <- map["documentServer"]
        mail <- map["mailServer"]
        xmpp <- map["xmppServer"]
        community <- map["communityServer"]
    }

    convenience init(
        docSpace: String? = nil,
        community: String? = nil,
        document: String? = nil,
        mail: String? = nil,
        xmpp: String? = nil
    ) {
        self.init()
        self.docSpace = docSpace
        self.community = community
        self.document = document
        self.mail = mail
        self.xmpp = xmpp
    }
}
