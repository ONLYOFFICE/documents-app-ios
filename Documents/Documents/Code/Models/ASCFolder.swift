//
//  ASCFolder.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright (c) 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

protocol FolderHolder: AnyObject {
    var folder: ASCFolder? { get set }
}

class ASCFolder: ASCEntity {
    var parentId: String?
    var filesCount: Int = 0
    var foldersCount: Int = 0
    var isShareable: Bool = false
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var roomType: ASCRoomType?
    var rootFolderType: ASCFolderType = .unknown
    var updated: Date?
    var updatedBy: ASCUser?
    var created: Date?
    var createdBy: ASCUser?
    var new: Int = 0
    var isThirdParty: Bool = false
    var providerType: ASCFolderProviderType?
    var device: Bool = false
    var parent: ASCFolder?
    var providerId: String? {
        if isThirdParty {
            return id.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        }
        return nil
    }

    override init() {
        super.init()
    }

    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        parentId <- (map["parentId"], ASCIndexTransform())
        filesCount <- map["filesCount"]
        foldersCount <- map["foldersCount"]
        isShareable <- map["isShareable"]
        title <- (map["title"], ASCStringTransform())
        access <- (map["access"], EnumTransform())
        shared <- map["shared"]
        roomType <- (map["roomType"], EnumTransform())
        rootFolderType <- (map["rootFolderType"], EnumTransform())
        updated <- (map["updated"], ASCDateTransform())
        updatedBy <- map["updatedBy"]
        created <- (map["created"], ASCDateTransform())
        createdBy <- map["createdBy"]
        new <- map["new"]
        isThirdParty <- map["providerItem"]
        providerType <- (map["providerKey"], EnumTransform())

        // Internal
        device <- map["device"]
    }

    func copy() -> ASCFolder {
        guard let folder = ASCFolder(JSON: toJSON()) else {
            let folder = ASCFolder()
            folder.parentId = parentId
            folder.filesCount = filesCount
            folder.foldersCount = foldersCount
            folder.isShareable = isShareable
            folder.title = title
            folder.access = access
            folder.shared = shared
            folder.rootFolderType = rootFolderType
            folder.updated = updated
            folder.updatedBy = updatedBy
            folder.created = created
            folder.createdBy = createdBy
            folder.new = new
            folder.isThirdParty = isThirdParty
            folder.providerType = providerType
            folder.device = device
            folder.parent = parent
            return folder
        }

        return folder
    }
}
