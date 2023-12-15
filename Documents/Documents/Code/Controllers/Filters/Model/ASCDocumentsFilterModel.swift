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

enum ApiFilterType: String {
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
    /// third party resource
    case dropBox
    case googleDrive
    case oneDrive
    case box

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
        case .googleDrive:
            return "3"
        case .oneDrive:
            return "5"
        case .box:
            return "1"
        }
    }
}

enum FiltersSection: String, CaseIterable {
    case type = "Type"
    case author = "Author"
    case search = "Search"
    case member
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
        case .googleDrive:
            return NSLocalizedString("Google Drive", comment: "")
        case .oneDrive:
            return NSLocalizedString("OneDrive", comment: "")
        case .box:
            return NSLocalizedString("Box", comment: "")
        }
    }
}
