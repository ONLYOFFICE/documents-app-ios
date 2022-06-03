//
//  ASCDocumentsFilterModel.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.04.2022.
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
        FilterViewModel(id: filterType.rawValue, isSelected: isSelected, filterName: filterName, isFilterResetBtnShowen: false)
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
                        defaultTextColor: Asset.Colors.brend.color)
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
    var defaultTextColor: UIColor = .black
}

struct ActionButtonViewModel {
    var text: String
    var backgroundColor: UIColor
    var textColor: UIColor
    var isActive: Bool = true

    static var empty = ActionButtonViewModel(text: "", backgroundColor: Asset.Colors.filterCapsule.color, textColor: Asset.Colors.brend.color, isActive: true)
}

enum ApiFilterType: String {
    case none = "None"
    case files = "FilesOnly"
    case folders = "FoldersOnly"
    case documents = "DocumentsOnly"
    case presentations = "PresentationsOnly"
    case spreadsheets = "SpreadsheetsOnly"
    case images = "ImagesOnly"
    case user = "ByUser"
    case group = "ByDepartment"
    case archive = "ArchiveOnly"
    case byExtension = "ByExtension"
    case media = "MediaOnly"
}

enum FiltersSection: String, CaseIterable {
    case type = "Type"
    case author = "Author"
    case search = "Search"

    func localizedString() -> String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

enum FiltersName: String, CaseIterable {
    case folders = "Folders"
    case documents = "Documents"
    case presentations = "Presentations"
    case spreadsheets = "Spreadsheets"
    case images = "Images"
    case media = "Media"
    case archives = "Archives"
    case allFiles = "All files"
    case users = "Users"
    case groups = "Groups"
    case search = "Search"
    case excludeSubfolders = "Exclude subfolders"

    func localizedString() -> String {
        return NSLocalizedString(rawValue, comment: "")
    }
}
