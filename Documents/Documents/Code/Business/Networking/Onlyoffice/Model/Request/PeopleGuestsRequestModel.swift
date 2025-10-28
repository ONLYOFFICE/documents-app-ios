//
//  PeopleGuestsRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct PeopleGuestsRequestModel: Encodable {
    var count = 100
    var sortby = "displayname"
    var sortorder = "ascending"
    let area = "guests"
    var includeShared: Bool? = nil
}
