//
//  ASCFile.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftUI

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
    var formFillingStatus: FormFillingStatus = .none
    var isForm: Bool = false
    var openVersionMode: Bool = false
    var order: String?
    var parent: ASCFolder?
    var pureContentLength: Int = 0
    var requestToken: String?
    var rootFolderType: ASCFolderType = .default
    var security: ASCFileSecurity = .init()
    var availableShareRights: ASCShareRights = ASCShareRights.defaults
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
        viewUrl <- map["viewUrl"]
        webUrl <- map["webUrl"]
        formFillingStatus <- (map["formFillingStatus"], EnumTransform())
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
        
        if let availableShareRights: ASCShareRights = try? map.value("availableShareRights"),
           !availableShareRights.isEmpty {
            self.availableShareRights = availableShareRights
        }

        // Internal
        device <- map["device"]

        /// This parameter is taken into account if it is necessary to work with a specific
        /// version of the file from the `version` property. In all other cases, the file
        /// will be opened without specifying the versioning, which will ensure that
        /// the actual version of the file is opened.
        openVersionMode <- map["openVersionMode"]
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

enum FormFillingStatus: Int, Codable {
    case none = 0
    case draft = 1
    case yourTurn = 2
    case inProgress = 3
    case complete = 4
    case stopped = 5

    var localizedString: String {
        switch self {
        case .none:
            ""
        case .draft:
            NSLocalizedString("Draft", comment: "Form filling status")
        case .yourTurn:
            NSLocalizedString("Your turn", comment: "Form filling status")
        case .inProgress:
            NSLocalizedString("In progress", comment: "Form filling status")
        case .complete:
            NSLocalizedString("Complete", comment: "Form filling status")
        case .stopped:
            NSLocalizedString("Stopped", comment: "Form filling status")
        }
    }

    var uiColor: UIColor {
        switch self {
        case .none: return .clear
        case .draft: return .systemRed
        case .yourTurn: return .systemBlue
        case .inProgress: return .gray
        case .complete: return .systemGreen
        case .stopped: return .systemRed
        }
    }

    var color: Color {
        if #available(iOS 15.0, *) {
            return Color(uiColor: uiColor)
        } else {
            switch self {
            case .none: return .clear
            case .draft: return .red
            case .yourTurn: return .blue
            case .inProgress: return .gray
            case .complete: return .green
            case .stopped: return .red
            }
        }
    }
}

extension ASCFile {
    func update(with file: ASCFile, ignore ignoredKeys: [PartialKeyPath<ASCFile>] = []) {
        // helper function
        func shouldUpdate<Value>(_ keyPath: KeyPath<ASCFile, Value>) -> Bool {
            !ignoredKeys.contains(where: { $0 == keyPath })
        }

        if shouldUpdate(\.extension) { self.extension = file.extension }
        if shouldUpdate(\.access) { access = file.access }
        if shouldUpdate(\.canShare) { canShare = file.canShare }
        if shouldUpdate(\.comment) { comment = file.comment }
        if shouldUpdate(\.created) { created = file.created }
        if shouldUpdate(\.createdBy) { createdBy = file.createdBy }
        if shouldUpdate(\.customFilterEnabled) { customFilterEnabled = file.customFilterEnabled }
        if shouldUpdate(\.denyDownload) { denyDownload = file.denyDownload }
        if shouldUpdate(\.device) { device = file.device }
        if shouldUpdate(\.displayContentLength) { displayContentLength = file.displayContentLength }
        if shouldUpdate(\.editable) { editable = file.editable }
        if shouldUpdate(\.expired) { expired = file.expired }
        if shouldUpdate(\.fileStatus) { fileStatus = file.fileStatus }
        if shouldUpdate(\.formFillingStatus) { formFillingStatus = file.formFillingStatus }
        if shouldUpdate(\.isForm) { isForm = file.isForm }
        if shouldUpdate(\.openVersionMode) { openVersionMode = file.openVersionMode }
        if shouldUpdate(\.order) { order = file.order }
        if shouldUpdate(\.parent) { parent = file.parent }
        if shouldUpdate(\.pureContentLength) { pureContentLength = file.pureContentLength }
        if shouldUpdate(\.requestToken) { requestToken = file.requestToken }
        if shouldUpdate(\.rootFolderType) { rootFolderType = file.rootFolderType }
        if shouldUpdate(\.security) { security = file.security }
        if shouldUpdate(\.shared) { shared = file.shared }
        if shouldUpdate(\.thumbnailStatus) { thumbnailStatus = file.thumbnailStatus }
        if shouldUpdate(\.thumbnailUrl) { thumbnailUrl = file.thumbnailUrl }
        if shouldUpdate(\.title) { title = file.title }
        if shouldUpdate(\.updated) { updated = file.updated }
        if shouldUpdate(\.updatedBy) { updatedBy = file.updatedBy }
        if shouldUpdate(\.version) { version = file.version }
        if shouldUpdate(\.viewUrl) { viewUrl = file.viewUrl }
        if shouldUpdate(\.webUrl) { webUrl = file.webUrl }
    }
}
