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
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var rootFolderType: ASCFolderType = .unknown
    var updated: Date?
    var updatedBy: ASCUser?
    var created: Date?
    var createdBy: ASCUser?
    var isNew: Bool = false
    var device: Bool = false
    var parent: ASCFolder? = nil
    
    override init() {
        super.init()
    }

    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        
        id                      <- (map["id"], ASCIndexTransform())
        version                 <- map["version"]
        displayContentLength    <- map["contentLength"]
        pureContentLength       <- map["pureContentLength"]
        fileStatus              <- (map["fileStatus"], EnumTransform())
        viewUrl                 <- map["viewUrl"]
        title                   <- (map["title"], ASCStringTransform())
        access                  <- (map["access"], EnumTransform())
        shared                  <- map["shared"]
        rootFolderType          <- (map["rootFolderType"], EnumTransform())
        updated                 <- (map["updated"], ASCDateTransform())
        updatedBy               <- map["updatedBy"]
        created                 <- (map["created"], ASCDateTransform())
        createdBy               <- map["createdBy"]
        device                  <- map["device"]
        isNew                   = fileStatus == .isNew
        
        // Internal
        device                  <- map["device"]
    }
}
