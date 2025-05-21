//
//  ASCFile.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCFile: ASCEntity {
    var `extension`: String?
    var access: ASCEntityAccess = .none
    var canShare: Bool = false
    var comment: String?
    var created: Date?
    var createdBy: ASCUser?
    var customFilterEnabled: Bool = false
    var denyDownload: Bool = false
    var device: Bool = false
    var displayContentLength: String?
    var editable: Bool = false
    var expired: Date?
    var fileStatus: ASCFileStatus = .none
    var isForm: Bool = false
    var order: String?
    var parent: ASCFolder?
    var pureContentLength: Int = 0
    var requestToken: String?
    var rootFolderType: ASCFolderType = .default
    var security: ASCFileSecurity = .init()
    var shared: Bool = false
    var thumbnailStatus: ASCThumbnailStatus?
    var thumbnailUrl: String?
    var title: String = ""
    var updated: Date?
    var updatedBy: ASCUser?
    var version: Int = 0
    var viewUrl: String?
    var webUrl: String?

    override init() {
        super.init()
    }

    required init?(map: Map) {
        super.init(map: map)
    }

    var isEditing: Bool {
        get { return fileStatus.contains(.isEditing) }
        set {
            if newValue {
                fileStatus.insert(.isEditing)
            } else {
                fileStatus.remove(.isEditing)
            }
        }
    }

    var isNew: Bool {
        get { return fileStatus.contains(.isNew) }
        set {
            if newValue {
                fileStatus.insert(.isNew)
            } else {
                fileStatus.remove(.isNew)
            }
        }
    }

    var isFavorite: Bool {
        get { return fileStatus.contains(.isFavorite) }
        set {
            if newValue {
                fileStatus.insert(.isFavorite)
            } else {
                fileStatus.remove(.isFavorite)
            }
        }
    }

    var isTemplate: Bool {
        get { return fileStatus.contains(.isTemplate) }
        set {
            if newValue {
                fileStatus.insert(.isTemplate)
            } else {
                fileStatus.remove(.isTemplate)
            }
        }
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        id <- (map["id"], ASCIndexTransform())
        `extension` <- map["extension"]
        access <- (map["access"], EnumTransform())
        canShare <- map["canShare"]
        comment <- map["comment"]
        created <- (map["created"], ASCDateTransform())
        createdBy <- map["createdBy"]
        customFilterEnabled <- map["customFilterEnabled"]
        denyDownload <- map["denyDownload"]
        device <- map["device"]
        displayContentLength <- map["contentLength"]
        expired <- (map["expired"], ASCDateTransform())
        fileStatus <- map["fileStatus"]
        isForm <- map["isForm"]
        order <- map["order"]
        pureContentLength <- map["pureContentLength"]
        rootFolderType <- (map["rootFolderType"], EnumTransform())
        security <- map["security"]
        shared <- map["shared"]
        thumbnailStatus <- (map["thumbnailStatus"], EnumTransform())
        thumbnailUrl <- map["thumbnailUrl"]
        title <- (map["title"], ASCStringTransform())
        updated <- (map["updated"], ASCDateTransform())
        updatedBy <- map["updatedBy"]
        version <- map["version"]
        viewUrl <- map["viewUrl"]
        webUrl <- map["webUrl"]

        // Internal
        device <- map["device"]
    }
}

extension ASCFile {
    var isExpiredSoon: Bool {
        guard let created, let expired, expired > created else { return false }

        let totalDuration = expired.timeIntervalSince(created)
        let timePassed = Date().timeIntervalSince(created)

        return timePassed >= totalDuration * 0.9
    }
}
