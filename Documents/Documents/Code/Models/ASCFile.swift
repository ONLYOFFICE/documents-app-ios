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
    var version: Int = 0
    var displayContentLength: String?
    var pureContentLength: Int = 0
    var fileStatus: ASCFileStatus = .none
    var viewUrl: String?
    var isForm: Bool = false
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var rootFolderType: ASCFolderType = .unknown
    var expired: Date?
    var updated: Date?
    var updatedBy: ASCUser?
    var created: Date?
    var createdBy: ASCUser?
    var device: Bool = false
    var parent: ASCFolder?
    var security: ASCFileSecurity = .init()
    var denyDownload: Bool = false
    var editable: Bool = false
    var canShare: Bool = false
    var requestToken: String?
    var `extension`: String?

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
        version <- map["version"]
        displayContentLength <- map["contentLength"]
        pureContentLength <- map["pureContentLength"]
        fileStatus <- map["fileStatus"]
        viewUrl <- map["viewUrl"]
        isForm <- map["isForm"]
        title <- (map["title"], ASCStringTransform())
        access <- (map["access"], EnumTransform())
        shared <- map["shared"]
        rootFolderType <- (map["rootFolderType"], EnumTransform())
        expired <- (map["expired"], ASCDateTransform())
        updated <- (map["updated"], ASCDateTransform())
        updatedBy <- map["updatedBy"]
        created <- (map["created"], ASCDateTransform())
        createdBy <- map["createdBy"]
        device <- map["device"]
        denyDownload <- map["denyDownload"]
        security <- map["security"]
        canShare <- map["canShare"]
        `extension` <- map["extension"]

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
