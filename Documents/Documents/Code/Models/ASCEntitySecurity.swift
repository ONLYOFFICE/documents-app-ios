//
//  ASCEntitySecurity.swift
//  Documents
//
//  Created by Pavel Chernyshev on 05/02/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCFileSecurity: Mappable {
    var read: Bool = false
    var comment: Bool = false
    var fillForms: Bool = false
    var review: Bool = false
    var edit: Bool = false
    var delete: Bool = false
    var customFilter: Bool = false
    var rename: Bool = false
    var readHistory: Bool = false
    var lock: Bool = false
    var editHistory: Bool = false
    var copy: Bool = false
    var move: Bool = false
    var duplicate: Bool = false
    var submitToFormGallery: Bool = false
    var download: Bool = false
    var convert: Bool = false
    var createRoomFrom: Bool = false
    var copyLink: Bool = false
    var embed: Bool = false
    var startFilling: Bool = false

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        read <- map["Read"]
        comment <- map["Comment"]
        fillForms <- map["FillForms"]
        review <- map["Review"]
        edit <- map["Edit"]
        delete <- map["Delete"]
        customFilter <- map["CustomFilter"]
        rename <- map["Rename"]
        readHistory <- map["ReadHistory"]
        lock <- map["Lock"]
        editHistory <- map["EditHistory"]
        copy <- map["Copy"]
        move <- map["Move"]
        duplicate <- map["Duplicate"]
        submitToFormGallery <- map["SubmitToFormGallery"]
        download <- map["Download"]
        convert <- map["Convert"]
        createRoomFrom <- map["CreateRoomFrom"]
        copyLink <- map["CopyLink"]
        embed <- map["Embed"]
        startFilling <- map["StartFilling"]
    }
}

class ASCFolderSecurity: Mappable {
    var read: Bool = false
    var create: Bool = false
    var delete: Bool = false
    var editRoom: Bool = false
    var rename: Bool = false
    var copyTo: Bool = false
    var copy: Bool = false
    var moveTo: Bool = false
    var move: Bool = false
    var pin: Bool = false
    var mute: Bool = false
    var editAccess: Bool = false
    var duplicate: Bool = false
    var download: Bool = false
    var copySharedLink: Bool = false
    var reconnect: Bool = false
    var createRoomFrom: Bool = false
    var copyLink: Bool = false
    var embed: Bool = false
    var changeOwner: Bool = false
    var indexExport: Bool = false

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        read <- map["Read"]
        create <- map["Create"]
        delete <- map["Delete"]
        editRoom <- map["EditRoom"]
        rename <- map["Rename"]
        copyTo <- map["CopyTo"]
        copy <- map["Copy"]
        moveTo <- map["MoveTo"]
        move <- map["Move"]
        pin <- map["Pin"]
        mute <- map["Mute"]
        editAccess <- map["EditAccess"]
        duplicate <- map["Duplicate"]
        download <- map["Download"]
        copySharedLink <- map["CopySharedLink"]
        reconnect <- map["Reconnect"]
        createRoomFrom <- map["CreateRoomFrom"]
        copyLink <- map["CopyLink"]
        embed <- map["Embed"]
        changeOwner <- map["ChangeOwner"]
        indexExport <- map["IndexExport"]
    }
}
