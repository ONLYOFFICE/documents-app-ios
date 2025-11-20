//
//  ASCFolder.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright (c) 2017 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import ObjectMapper
import UIKit

protocol FolderHolder: AnyObject {
    var folder: ASCFolder? { get set }
}

typealias ASCRoom = ASCFolder

class ASCFolder: ASCEntity {
    var parentId: String?
    var filesCount: Int = 0
    var foldersCount: Int = 0
    var isShareable: Bool = false
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var pinned: Bool = false
    var mute: Bool = false
    var roomType: ASCRoomType?
    var isPrivate: Bool = false
    var type: ASCFolderType?
    var isCanLeaveRoom: Bool = false
    var rootFolderType: ASCFolderType = .default
    var updated: Date?
    var updatedBy: ASCUser?
    var isFavorite: Bool?
    var created: Date?
    var createdBy: ASCUser?
    var new: Int = 0
    var isThirdParty: Bool = false
    var providerType: ASCFolderProviderType?
    var device: Bool = false
    var parent: ASCFolder?
    var logo: ASCFolderLogo?
    var tags: [String]?
    var security: ASCFolderSecurity = .init()
    var availableShareRights: ASCShareRights = .init()
    var indexing: Bool = false
    var denyDownload: Bool = false
    var lifetime: LifeTime?
    var watermark: Watermark?
    var order: String?
    var passwordProtected: Bool = false
    var requestToken: String?
    var quotaLimit: Double?
    var isCustomQuota: Bool = false

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
        pinned <- map["pinned"]
        mute <- map["mute"]
        roomType <- (map["roomType"], EnumTransform())
        isPrivate <- map["private"]
        type <- (map["type"], EnumTransform())
        rootFolderType <- (map["rootFolderType"], EnumTransform())
        updated <- (map["updated"], ASCDateTransform())
        updatedBy <- map["updatedBy"]
        isFavorite <- map["isFavorite"]
        created <- (map["created"], ASCDateTransform())
        createdBy <- map["createdBy"]
        new <- map["new"]
        isThirdParty <- map["providerItem"]
        logo <- map["logo"]
        tags <- map["tags"]
        providerType <- (map["providerKey"], EnumTransform())
        security <- map["security"]
        availableShareRights <- map["availableShareRights"]
        indexing <- map["indexing"]
        denyDownload <- map["denyDownload"]
        lifetime <- map["lifetime"]
        watermark <- map["watermark"]
        order <- map["order"]
        passwordProtected <- map["passwordProtected"]
        requestToken <- map["requestToken"]
        quotaLimit <- map["quotaLimit"]
        isCustomQuota <- map["isCustomQuota"]
        // Internal
        device <- map["device"]
        // TODO: Do not forget update copy() when add a new field
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
            folder.pinned = pinned
            folder.mute = mute
            folder.roomType = roomType
            folder.isPrivate = isPrivate
            folder.type = type
            folder.rootFolderType = rootFolderType
            folder.updated = updated
            folder.updatedBy = updatedBy
            folder.isFavorite = isFavorite
            folder.created = created
            folder.createdBy = createdBy
            folder.new = new
            folder.isThirdParty = isThirdParty
            folder.logo = logo
            folder.tags = tags
            folder.providerType = providerType
            folder.security = security
            folder.indexing = indexing
            folder.denyDownload = denyDownload
            folder.lifetime = lifetime
            folder.watermark = watermark
            folder.order = order
            folder.passwordProtected = passwordProtected
            folder.requestToken = requestToken
            folder.quotaLimit = quotaLimit
            folder.isCustomQuota = isCustomQuota
            folder.device = device
            folder.parent = parent
            return folder
        }

        return folder
    }
}

// MARK: - Subtypes

extension ASCFolder {
    final class LifeTime: Mappable {
        var deletePermanently: Bool = false
        var period: Int?
        var value: Int?

        init?(map: ObjectMapper.Map) {}

        init() {}

        func mapping(map: ObjectMapper.Map) {
            deletePermanently <- map["deletePermanently"]
            period <- map["period"]
            value <- map["value"]
        }
    }

    final class Watermark: Mappable {
        var additions: Int?
        var rotate: Int?
        var text: String?
        var imageScale: Int?
        var imageUrl: String?
        var imageHeight: Int?
        var imageWidth: Int?

        init?(map: ObjectMapper.Map) {}

        init() {}

        func mapping(map: ObjectMapper.Map) {
            additions <- map["additions"]
            rotate <- map["rotate"]
            text <- map["text"]
            imageScale <- map["imageScale"]
            imageUrl <- map["imageUrl"]
            imageHeight <- map["imageHeight"]
            imageWidth <- map["imageWidth"]
        }
    }
}

extension ASCFolder.LifeTime {
    func formattedLifetimeString() -> String? {
        guard let value = value, let period = period else { return nil }

        let unitLocalized: String = {
            switch period {
            case 0:
                return String(format: NSLocalizedString("%d days", comment: ""), value)
            case 1:
                return String(format: NSLocalizedString("%d months", comment: ""), value)
            case 2:
                return String(format: NSLocalizedString("%d years", comment: ""), value)
            default:
                return ""
            }
        }()

        return String(format: NSLocalizedString("The file lifetime is set to %@ in this room.", comment: ""), unitLocalized)
    }
}

extension ASCFolder {
    var isRoot: Bool {
        parentId == nil || parentId == "0"
    }
}

extension ASCFolder {
    var isEmpty: Bool {
        filesCount == 0 && foldersCount == 0
    }
}

// MARK: - ASCEntity extension for DocSpace

extension ASCEntity {
    var isRoom: Bool {
        guard let folder = self as? ASCFolder, folder.roomType != nil else { return false }
        return true
    }
}

// MARK: - ASCFolder extension for DocSpace

extension ASCFolder {
    var currentOrParentsRoom: ASCRoom? {
        guard !isRoom else { return self }
        var currentFolder = self

        while let parentFolder = currentFolder.parent {
            if parentFolder.isRoom {
                return parentFolder
            }
            currentFolder = parentFolder
        }
        return nil
    }

    var isRoomListFolder: Bool {
        isRoot && ASCOnlyofficeCategory.hasDocSpaceRootRoomsList(type: rootFolderType)
    }

    var isRoomListSubfolder: Bool {
        ASCOnlyofficeCategory.hasDocSpaceRootRoomsList(type: rootFolderType) && !isRoomListFolder
    }

    func parentsFoldersContains<Value>(keyPath: KeyPath<ASCFolder, Value>, value: Value) -> Bool where Value: Equatable {
        var currentFolder = self

        while let parentFolder = currentFolder.parent {
            if parentFolder[keyPath: keyPath] == value {
                return true
            }
            currentFolder = parentFolder
        }

        return false
    }

    func parentsFoldersOrCurrentContains<Value>(keyPath: KeyPath<ASCFolder, Value>, value: Value) -> Bool where Value: Equatable {
        self[keyPath: keyPath] == value || parentsFoldersContains(keyPath: keyPath, value: value)
    }
}

extension ASCFolder {
    var isPublicRoom: Bool {
        return isRoom && roomType == .public
    }

    var isFillingFormRoom: Bool {
        return isRoom && roomType == .fillingForm
    }

    var isCollaborationRoom: Bool {
        return isRoom && roomType == .colobaration
    }

    var isCustomRoom: Bool {
        return isRoom && roomType == .custom
    }

    var isTemplateRoom: Bool {
        return isRoom && rootFolderType == .roomTemplates
    }
}

extension ASCFolder {
    static var onlyofficeRoomSharedFolder: ASCFolder {
        let folder = ASCFolder()
        folder.rootFolderType = .virtualRooms
        folder.id = "rooms"
        folder.title = NSLocalizedString("Rooms", comment: "")
        return folder
    }

    static var onlyofficeRootFolder: ASCFolder {
        let folder = ASCFolder()
        folder.id = "id-onlyoffice-root"
        folder.title = NSLocalizedString("DocSpace", comment: "")
        return folder
    }
}

extension ASCFolder {
    func defaultRoomImage(layoutType: ASCEntityViewLayoutType) -> UIImage? {
        let folder = self

        let size = roomIconSize(layoutType: layoutType)
        var color = Asset.Colors.roomDefault.color

        if folder.rootFolderType == .archive {
            color = Asset.Colors.roomArchive.color
        } else if let hexColor = folder.logo?.color {
            color = UIColor(hex: "#\(hexColor)")
        }

        let canvasView = UIView(frame: CGRect(origin: .zero, size: size))
        canvasView.backgroundColor = UIColor(light: color, dark: color.withAlphaComponent(0.2))
        let literalLabel = {
            $0.font = UIFont.systemFont(ofSize: layoutType == .grid ? 36 : 17, weight: .semibold)
            $0.textColor = UITraitCollection.current.userInterfaceStyle == .dark ? color.withAlphaComponent(1.0) : .white
            $0.textAlignment = .center
            $0.text = formatFolderName(folderName: folder.title)
            return $0
        }(UILabel(frame: canvasView.frame))

        canvasView.addSubview(literalLabel)
        literalLabel.anchorCenterSuperview()
        canvasView.layerCornerRadius = roomIconRadius(layoutType: layoutType)
        canvasView.layoutSubviews()

        return canvasView.screenshot
    }

    func roomIconSize(layoutType: ASCEntityViewLayoutType) -> CGSize {
        layoutType == .grid ? Constants.gridRoomIconSize : Constants.listRoomIconSize
    }

    func roomIconRadius(layoutType: ASCEntityViewLayoutType) -> CGFloat {
        layoutType == .grid ? Constants.gridRoomIconRadius : Constants.listRoomIconRadius
    }

    func formatFolderName(folderName: String) -> String {
        folderName.components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" }
            .uppercased()
    }
}

extension ASCFolder {
    enum Constants {
        static let listRoomIconSize = CGSize(width: 36, height: 36)
        static let gridRoomIconSize = CGSize(width: 80, height: 80)
        static let listRoomIconRadius: CGFloat = 8
        static let gridRoomIconRadius: CGFloat = 18
    }
}
