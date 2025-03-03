//
//  CompletedFormResponceModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 18.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class CompletedFormResponceModel: Mappable {
    var formNumber: Int = 0
    var completedForm: ASCFile?
    var roomId: Int = 0
    var manager: FormManager?

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        formNumber <- map["formNumber"]
        completedForm <- map["completedForm"]
        roomId <- map["roomId"]
        manager <- map["manager"]
    }
}

class FormManager: Mappable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var displayName: String?
    var avatar: String?

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        firstName <- map["firstName"]
        lastName <- map["lastName"]
        email <- map["email"]
        displayName <- map["displayName"]
        avatar <- map["avatar"]
    }
}
