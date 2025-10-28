//
//  PeopleRoomRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct PeopleRoomRequestModel: Encodable {
    var count = 100
    var sortby = "displayname"
    var sortorder = "ascending"
    let area = "people"
    var includeShared: String? = "true"
}
