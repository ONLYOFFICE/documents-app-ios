//
//  ASCDocumentsFilterModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol FilterTypeConvirtable {
    func convert() -> FilterViewModel
}

struct ASCDocumentsFilterModel: FilterTypeConvirtable {
    var filterName: String
    var isSelected: Bool
    var filterType: ApiFilterType

    func convert() -> FilterViewModel {
        FilterViewModel(
            id: filterType.rawValue,
            isSelected: isSelected,
            filterName: filterName,
            isFilterResetBtnShowen: false,
            defaultTextColor: Asset.Colors.textSubtitle.color
        )
    }
}

struct ActionFilterModel: FilterTypeConvirtable {
    var id: String? = nil
    var defaultName: String
    var selectedName: String?
    var filterType: ApiFilterType

    func convert() -> FilterViewModel {
        FilterViewModel(id: filterType.rawValue,
                        isSelected: selectedName != nil,
                        filterName: selectedName ?? defaultName,
                        isFilterResetBtnShowen: selectedName != nil,
                        defaultTextColor: Asset.Colors.textSubtitle.color)
    }
}

struct ASCDocumentsSectionViewModel {
    var sectionName: String
    var filters: [FilterViewModel]
}

struct FiltersCollectionViewModel {
    enum State {
        case normal
        case loading
    }

    var state: State = .normal
    var data: [ASCDocumentsSectionViewModel]
    var actionButtonViewModel: ActionButtonViewModel

    var actionButtonClosure: () -> Void
    var resetButtonClosure: () -> Void
    var didSelectedClosure: (_ filterViewModel: FilterViewModel) -> Void
    var didFilterResetBtnTapped: (_ filterViewModel: FilterViewModel) -> Void

    static var empty = FiltersCollectionViewModel(data: [], actionButtonViewModel: .empty) {} resetButtonClosure: {} didSelectedClosure: { _ in } didFilterResetBtnTapped: { _ in }
}

struct FilterViewModel {
    var id: String
    var isSelected: Bool
    var filterName: String
    var isFilterResetBtnShowen: Bool
    var defaultTextColor: UIColor = Asset.Colors.textSubtitle.color
}

struct ActionButtonViewModel {
    var text: String
    var backgroundColor: UIColor
    var textColor: UIColor
    var isActive: Bool = true

    static var empty = ActionButtonViewModel(
        text: "",
        backgroundColor: Asset.Colors.filterCapsule.color,
        textColor: Asset.Colors.brend.color,
        isActive: true
    )
}

enum ApiFilterType {
    case none
    case files
    case folders
    case documents
    case presentations
    case spreadsheets
    case formTemplates
    case forms
    case images
    case me
    case user
    case group
    case archive
    case byExtension
    case media
    case excludeSubfolders
    /// rooms
    case customRoom
    case fillingFormRoom
    case collaborationRoom
    case publicRoom
    case reviewRoom
    case viewOnlyRoom
    case tag(String)
    /// third party resource
    case dropBox
    case nextCloud
    case googleDrive
    case oneDrive
    case box

    var rawValue: String {
        switch self {
        case .none:
            return "none"
        case .files:
            return "files"
        case .folders:
            return "folders"
        case .documents:
            return "documents"
        case .presentations:
            return "presentations"
        case .spreadsheets:
            return "spreadsheets"
        case .formTemplates:
            return "formTemplates"
        case .forms:
            return "forms"
        case .images:
            return "images"
        case .me:
            return "me"
        case .user:
            return "user"
        case .group:
            return "group"
        case .archive:
            return "archive"
        case .byExtension:
            return "byExtension"
        case .media:
            return "media"
        case .excludeSubfolders:
            return "excludeSubfolders"
        case let .tag(tag):
            return tag
        case .customRoom:
            return "customRoom"
        case .fillingFormRoom:
            return "fillingFormRoom"
        case .collaborationRoom:
            return "collaborationRoom"
        case .reviewRoom:
            return "reviewRoom"
        case .viewOnlyRoom:
            return "viewOnlyRoom"
        case .publicRoom:
            return "publicRoom"
        case .dropBox:
            return "dropBox"
        case .nextCloud:
            return "nextCloud"
        case .googleDrive:
            return "3"
        case .oneDrive:
            return "googleDrive"
        case .box:
            return "box"
        }
    }

    var filterValue: String {
        switch self {
        case .none:
            return "None"
        case .files:
            return "FilesOnly"
        case .folders:
            return "FoldersOnly"
        case .documents:
            return "DocumentsOnly"
        case .presentations:
            return "PresentationsOnly"
        case .spreadsheets:
            return "SpreadsheetsOnly"
        case .formTemplates:
            return "18"
        case .forms:
            return "19"
        case .images:
            return "ImagesOnly"
        case .me, .user:
            return "ByUser"
        case .group:
            return "ByDepartment"
        case .archive:
            return "ArchiveOnly"
        case .byExtension:
            return "ByExtension"
        case .media:
            return "MediaOnly"
        case .excludeSubfolders:
            return "excludeSubfolders"
        case let .tag(tag):
            return tag
        case .customRoom:
            return "5"
        case .fillingFormRoom:
            return "1"
        case .collaborationRoom:
            return "2"
        case .reviewRoom:
            return "3"
        case .viewOnlyRoom:
            return "4"
        case .publicRoom:
            return "6"
        case .dropBox:
            return "2"
        case .nextCloud:
            return "7"
        case .googleDrive:
            return "3"
        case .oneDrive:
            return "5"
        case .box:
            return "1"
        }
    }
}

extension ApiFilterType {
    init?(rawValue: String) {
        switch rawValue {
        case "none":
            self = .none
        case "files":
            self = .files
        case "folders":
            self = .folders
        case "documents":
            self = .documents
        case "presentations":
            self = .presentations
        case "spreadsheets":
            self = .spreadsheets
        case "formTemplates":
            self = .formTemplates
        case "forms":
            self = .forms
        case "images":
            self = .images
        case "me":
            self = .me
        case "user":
            self = .user
        case "group":
            self = .group
        case "archive":
            self = .archive
        case "byExtension":
            self = .byExtension
        case "media":
            self = .media
        case "excludeSubfolders":
            self = .excludeSubfolders
        case "customRoom":
            self = .customRoom
        case "fillingFormRoom":
            self = .fillingFormRoom
        case "collaborationRoom":
            self = .collaborationRoom
        case "reviewRoom":
            self = .reviewRoom
        case "viewOnlyRoom":
            self = .viewOnlyRoom
        case "publicRoom":
            self = .publicRoom
        case "dropBox":
            self = .dropBox
        case "nextCloud":
            self = .nextCloud
        case "googleDrive":
            self = .googleDrive
        case "oneDrive":
            self = .oneDrive
        case "box":
            self = .box
        default:
            return nil
        }
    }
}

extension ApiFilterType: Equatable {
    static func == (lhs: ApiFilterType, rhs: ApiFilterType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.files, .files),
             (.folders, .folders),
             (.documents, .documents),
             (.presentations, .presentations),
             (.spreadsheets, .spreadsheets),
             (.formTemplates, .formTemplates),
             (.forms, .forms), (.images, .images),
             (.me, .me),
             (.user, .user),
             (.group, .group),
             (.archive, .archive),
             (.byExtension, .byExtension),
             (.media, .media),
             (.excludeSubfolders, .excludeSubfolders),
             (.customRoom, .customRoom),
             (.fillingFormRoom, .fillingFormRoom),
             (.collaborationRoom, .collaborationRoom),
             (.reviewRoom, .reviewRoom),
             (.viewOnlyRoom, .viewOnlyRoom),
             (.publicRoom, .publicRoom),
             (.dropBox, .dropBox),
             (.nextCloud, .nextCloud),
             (.googleDrive, .googleDrive),
             (.oneDrive, .oneDrive),
             (.box, .box):
            return true
        case let (.tag(leftTag), .tag(rightTag)):
            return leftTag == rightTag
        default:
            return false
        }
    }
}

enum FiltersSection: String, CaseIterable {
    case type = "Type"
    case author = "Author"
    case search = "Search"
    case member
    case tags
    case thirdPartyResource

    func localizedString() -> String {
        switch self {
        case .type:
            return NSLocalizedString("Type", comment: "")
        case .author:
            return NSLocalizedString("Author", comment: "")
        case .search:
            return NSLocalizedString("Search", comment: "")
        case .member:
            return NSLocalizedString("Member", comment: "")
        case .tags:
            return NSLocalizedString("Tags", comment: "")
        case .thirdPartyResource:
            return NSLocalizedString("Third party resource", comment: "")
        }
    }
}

enum FiltersName: String, CaseIterable {
    case folders
    case documents
    case presentations
    case spreadsheets
    case formTemplates
    case forms
    case images
    case media
    case archives
    case allFiles
    case me
    case users
    case groups
    case search
    case excludeSubfolders
    /// rooms
    case customRoom
    case collaborationRoom
    case publicRoom
    /// third party resource
    case dropBox
    case nextCloud
    case googleDrive
    case oneDrive
    case box

    func localizedString() -> String {
        switch self {
        case .folders:
            return NSLocalizedString("Folders", comment: "")
        case .documents:
            return NSLocalizedString("Documents", comment: "")
        case .presentations:
            return NSLocalizedString("Presentations", comment: "")
        case .spreadsheets:
            return NSLocalizedString("Spreadsheets", comment: "")
        case .formTemplates:
            return NSLocalizedString("Form templates", comment: "")
        case .forms:
            return NSLocalizedString("Forms", comment: "")
        case .images:
            return NSLocalizedString("Images", comment: "")
        case .media:
            return NSLocalizedString("Media", comment: "")
        case .archives:
            return NSLocalizedString("Archives", comment: "")
        case .allFiles:
            return NSLocalizedString("All files", comment: "")
        case .me:
            return NSLocalizedString("Me", comment: "Author or member of a document")
        case .users:
            return NSLocalizedString("Users", comment: "")
        case .groups:
            return NSLocalizedString("Groups", comment: "")
        case .search:
            return NSLocalizedString("Search", comment: "")
        case .excludeSubfolders:
            return NSLocalizedString("Exclude subfolders", comment: "")
        case .customRoom:
            return NSLocalizedString("Custom", comment: "")
        case .collaborationRoom:
            return NSLocalizedString("Collaboration", comment: "")
        case .publicRoom:
            return NSLocalizedString("Public", comment: "")
        case .dropBox:
            return NSLocalizedString("Dropbox", comment: "")
        case .nextCloud:
            return NSLocalizedString("NextCloud", comment: "")
        case .googleDrive:
            return NSLocalizedString("Google Drive", comment: "")
        case .oneDrive:
            return NSLocalizedString("OneDrive", comment: "")
        case .box:
            return NSLocalizedString("Box", comment: "")
        }
    }
}
