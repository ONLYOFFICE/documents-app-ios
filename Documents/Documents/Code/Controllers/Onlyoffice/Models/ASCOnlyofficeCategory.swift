//
//  ASCOnlyofficeCategory.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyofficeCategory: ASCCategory {
    var sortWeight = 500

    var isDocSpaceRoom: Bool {
        Self.isDocSpace(type: folder?.rootFolderType ?? .default)
    }

    convenience init(folder: ASCFolder) {
        let folder = folder.copy()
        self.init()
        self.folder = folder
        title = folder.title.isEmpty
            ? Self.title(of: folder.rootFolderType)
            : folder.title
        image = Self.image(of: folder.rootFolderType)
        self.folder?.id = Self.id(of: folder.rootFolderType)
        sortWeight = Self.sortWeight(of: folder.rootFolderType)
    }

    static func title(of type: ASCFolderType) -> String {
        switch type {
        case .user:
            return ASCOnlyofficeProvider.isDocspaceApi
                ? NSLocalizedString("Documents", comment: "Category title")
                : NSLocalizedString("My Documents", comment: "Category title")
        case .share:
            return NSLocalizedString("Shared with Me", comment: "Category title")
        case .favorites:
            return NSLocalizedString("Favorites", comment: "Category title")
        case .recent:
            return NSLocalizedString("Recent", comment: "Category title")
        case .virtualRooms:
            return NSLocalizedString("Rooms", comment: "Category title")
        case .archive:
            return NSLocalizedString("Archive", comment: "Category title")
        case .common:
            return NSLocalizedString("Common Documents", comment: "Category title")
        case .bunch, .projects:
            return NSLocalizedString("Project Documents", comment: "Category title")
        case .trash:
            return NSLocalizedString("Trash", comment: "Category title")
        default:
            return ""
        }
    }

    static func image(of type: ASCFolderType) -> UIImage? {
        switch type {
        case .common:
            return Asset.Images.categoryCommon.image
        case .trash:
            return Asset.Images.categoryTrash.image
        case .user:
            return Asset.Images.categoryMy.image
        case .share:
            return Asset.Images.categoryShare.image
        case .virtualRooms:
            return Asset.Images.categoryRoom.image
        case .archive:
            return Asset.Images.categoryArchived.image
        case .bunch, .projects:
            return Asset.Images.categoryProjects.image
        case .favorites:
            return Asset.Images.categoryFavorites.image
        case .recent:
            return Asset.Images.categoryRecent.image
        default:
            return nil
        }
    }

    static func sortWeight(of type: ASCFolderType) -> Int {
        switch type {
        case .user:
            return 10
        case .share, .virtualRooms:
            return 20
        case .archive:
            return 25
        case .favorites:
            return 30
        case .recent:
            return 40
        case .common:
            return 60
        case .bunch, .projects:
            return 70
        case .trash:
            return 80
        default:
            return 500
        }
    }

    static func id(of type: ASCFolderType) -> String {
        switch type {
        case .user:
            return OnlyofficeAPI.Path.Folder.my
        case .share:
            return OnlyofficeAPI.Path.Folder.share
        case .virtualRooms:
            return OnlyofficeAPI.Path.Folder.room
        case .archive:
            return OnlyofficeAPI.Path.Folder.room
        case .favorites:
            return OnlyofficeAPI.Path.Folder.favorites
        case .recent:
            return OnlyofficeAPI.Path.Folder.recent
        case .common:
            return OnlyofficeAPI.Path.Folder.common
        case .bunch, .projects:
            return OnlyofficeAPI.Path.Folder.projects
        case .trash:
            return OnlyofficeAPI.Path.Folder.trash
        default:
            return ""
        }
    }

    static func isDocSpace(type: ASCFolderType) -> Bool {
        guard ASCFileManager.onlyofficeProvider?.apiClient.serverVersion?.docSpace != nil else { return false }
        switch type {
        case .virtualRooms, .archive, .user, .recent, .roomTemplates:
            return true
        default:
            return false
        }
    }

    static func hasDocSpaceRootRoomsList(type: ASCFolderType) -> Bool {
        guard isDocSpace(type: type), ASCFileManager.onlyofficeProvider?.apiClient.serverVersion?.docSpace != nil else { return false }
        switch type {
        case .virtualRooms, .archive, .roomTemplates:
            return true
        default:
            return false
        }
    }

    static func searchArea(of type: ASCFolderType) -> String? {
        switch type {
        case .virtualRooms:
            return OnlyofficeSearchArea.active.rawValue
        case .archive:
            return OnlyofficeSearchArea.archive.rawValue
        case .recent:
            return OnlyofficeSearchArea.recentByLinks.rawValue
        case .roomTemplates:
            return OnlyofficeSearchArea.templates.rawValue
        default:
            return nil
        }
    }

    static func allowToMoveAndCopy(of type: ASCFolderType) -> Bool {
        switch type {
        case .user:
            return true
        case .share:
            return true
        case .common:
            return true
        case .bunch, .projects:
            return true
        case .virtualRooms:
            return true
        default:
            return false
        }
    }

    static func allowToMoveAndCopy(category: ASCOnlyofficeCategory) -> Bool {
        allowToMoveAndCopy(of: category.folder?.rootFolderType ?? .default)
    }

    static func folder(of type: ASCFolderType) -> ASCFolder? {
        switch type {
        case .user,
             .share,
             .virtualRooms,
             .common,
             .projects,
             .trash:
            return {
                $0.title = Self.title(of: type)
                $0.rootFolderType = type
                $0.id = Self.id(of: type)
                return $0
            }(ASCFolder())
        case .bunch:
            return {
                $0.title = Self.title(of: .projects)
                $0.rootFolderType = .projects
                $0.id = Self.id(of: .projects)
                return $0
            }(ASCFolder())
        default:
            return nil
        }
    }

    // MARK: - Codable requires

    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        super.init()
        try decode(from: decoder)
    }
}

// MARK: - Codable realization

extension ASCOnlyofficeCategory: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case folderId
        case rootFolderTypeRaw
        case subtitle
        case sort
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let title = title {
            try container.encode(title, forKey: .title)
        }
        if let folderId = folder?.id {
            try container.encode(folderId, forKey: .folderId)
        }
        if let rootFolderType = folder?.rootFolderType {
            try container.encode(rootFolderType.rawValue, forKey: .rootFolderTypeRaw)
        }
        if let subtitle = subtitle {
            try container.encode(subtitle, forKey: .subtitle)
        }
        try container.encode(sortWeight, forKey: .sort)
    }

    func decode(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        title = try? values.decode(String.self, forKey: .title)
        subtitle = try? values.decode(String.self, forKey: .subtitle)
        sortWeight = try values.decode(Int.self, forKey: .sort)

        guard let rootFolderTypeRaw = try? values.decode(Int.self, forKey: .rootFolderTypeRaw),
              let rootFolderType = ASCFolderType(rawValue: rootFolderTypeRaw),
              let folderId = try? values.decode(String.self, forKey: .folderId)
        else {
            return
        }

        let folder = ASCFolder()
        folder.id = folderId
        folder.rootFolderType = rootFolderType
        folder.title = title ?? Self.title(of: rootFolderType)
        image = Self.image(of: rootFolderType)
        self.folder = folder
    }
}

// MARK: - Equatable

extension ASCOnlyofficeCategory: Equatable {
    static func == (lhs: ASCOnlyofficeCategory, rhs: ASCOnlyofficeCategory) -> Bool {
        return lhs.folder?.id == rhs.folder?.id
            && lhs.folder?.rootFolderType == rhs.folder?.rootFolderType
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.provider?.id == rhs.provider?.id
    }
}
