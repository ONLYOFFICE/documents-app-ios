//
//  ASCUser.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright (c) 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class ASCUser: Mappable {
    var userId: String?
    var displayName: String?
    var userName: String?
    var firstName: String?
    var lastName: String?
    var title: String?
    var avatarSmall: String?
    var department: String?
    var email: String?
    var avatar: String?
    var avatarRetina: String?
    var isAdmin: Bool = false
    var isRoomAdmin: Bool = false
    var isVisitor: Bool = false
    var isCollaborator: Bool = false
    var isOwner: Bool = false
    var accessValue: ASCShareAccess = .none
    var activationStatus: ActivationStatus = .applyed

    var userType: UserType {
        return isAdmin ? .docspaseAdmin : isVisitor ? .user : isCollaborator ? .powerUser : .roomAdmin
    }

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        userId <- (map["id"], ASCIndexTransform())
        displayName <- (map["displayName"], ASCStringTransform())
        userName <- (map["userName"], ASCStringTransform())
        firstName <- (map["firstName"], ASCStringTransform())
        lastName <- (map["lastName"], ASCStringTransform())
        title <- (map["title"], ASCStringTransform())
        avatarSmall <- map["avatarSmall"]
        department <- (map["department"], ASCStringTransform())
        email <- map["email"]
        avatar <- map["avatar"]
        avatarRetina <- map["avatarRetina"]
        isAdmin <- map["isAdmin"]
        isRoomAdmin <- map["isRoomAdmin"]
        isVisitor <- map["isVisitor"]
        isCollaborator <- map["isCollaborator"]
        isOwner <- map["isOwner"]
        accessValue <- (map["access"], EnumTransform())
        activationStatus <- (map["activationStatus"], EnumTransform())

        if let _ = map.JSON["sharedTo"] {
            displayName <- (map["sharedTo.displayName"], ASCStringTransform())
            userId <- map["sharedTo.id"]
        }
    }
}

extension ASCUser {
    enum ActivationStatus: Int, Codable {
        case applyed
        case owner
        case unapplyed
    }
}

extension ASCUser: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "id"
        case displayName
        case userName
        case firstName
        case lastName
        case title
        case avatarSmall
        case department
        case email
        case avatar
        case avatarRetina
        case isAdmin
        case isRoomAdmin
        case isVisitor
        case isCollaborator
        case isOwner
        case accessValue = "access"
        case activationStatus
        case sharedTo
    }

    convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        avatarSmall = try container.decodeIfPresent(String.self, forKey: .avatarSmall)
        department = try container.decodeIfPresent(String.self, forKey: .department)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        avatarRetina = try container.decodeIfPresent(String.self, forKey: .avatarRetina)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        isRoomAdmin = try container.decodeIfPresent(Bool.self, forKey: .isRoomAdmin) ?? false
        isVisitor = try container.decodeIfPresent(Bool.self, forKey: .isVisitor) ?? false
        isCollaborator = try container.decodeIfPresent(Bool.self, forKey: .isCollaborator) ?? false
        isOwner = try container.decodeIfPresent(Bool.self, forKey: .isOwner) ?? false
        accessValue = try container.decodeIfPresent(ASCShareAccess.self, forKey: .accessValue) ?? .none
        activationStatus = try container.decodeIfPresent(ASCUser.ActivationStatus.self, forKey: .activationStatus) ?? .applyed
        if let sharedTo = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .sharedTo) {
            displayName = try sharedTo.decodeIfPresent(String.self, forKey: .displayName)
            userId = try sharedTo.decodeIfPresent(String.self, forKey: .userId)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(userName, forKey: .userName)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(title, forKey: .title)
        try container.encode(avatarSmall, forKey: .avatarSmall)
        try container.encode(department, forKey: .department)
        try container.encode(email, forKey: .email)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(avatarRetina, forKey: .avatarRetina)
        try container.encode(isAdmin, forKey: .isAdmin)
        try container.encode(isRoomAdmin, forKey: .isRoomAdmin)
        try container.encode(isVisitor, forKey: .isVisitor)
        try container.encode(isCollaborator, forKey: .isCollaborator)
        try container.encode(isOwner, forKey: .isOwner)
        try container.encode(accessValue, forKey: .accessValue)
        try container.encode(activationStatus, forKey: .activationStatus)
        var sharedTo = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .sharedTo)
        try sharedTo.encode(displayName, forKey: .displayName)
        try sharedTo.encode(userId, forKey: .userId)
    }
}
