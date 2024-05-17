//
//  PeopleFilterRequestModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct PeopleFilterRequestModel: Codable {
    var count = 100
    var sortby = "firstname"
    var sortorder = "ascending"
    var filtervalue: String?
    var fields: [Field] = Field.allCases

    var dictionary: [String: Any]? {
        let fieldsString = fields.map { $0.rawValue }.joined(separator: ",")
        var addirionParams: [String: Any] = [:]
        if let filtervalue = filtervalue {
            addirionParams["filtervalue"] = filtervalue
        }
        return [
            "count": count,
            "sortby": sortby,
            "sortorder": sortorder,
            "fields": fieldsString,
        ].merging(addirionParams) { $1 }
    }
}

extension PeopleFilterRequestModel {
    enum Field: String, CaseIterable, Codable {
        case id
        case status
        case isAdmin
        case isOwner
        case isRoomAdmin
        case isVisitor
        case activationStatus
        case userName
        case email
        case mobilePhone
        case displayName
        case avatar
        case listAdminModules
        case birthday
        case title
        case location
        case isLDAP
        case isSSO
        case groups
    }
}
