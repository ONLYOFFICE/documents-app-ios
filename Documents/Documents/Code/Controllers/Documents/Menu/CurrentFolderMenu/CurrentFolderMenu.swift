//
//  CurrentFolderMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol CurrentFolderMenuProtocol {
    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu
    func actionSheet(for folder: ASCFolder, sender: UIView?, in viewController: ASCDocumentsViewController) -> UIAlertController
}

// MARK: Sort

extension CurrentFolderMenuProtocol {
    var sortInfoOnRootFolderType: [String: Any] {
        UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] ?? [:]
    }

    var sortInfo: [String: Any]? {
        UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any]
    }

    func sortInfo(forRootFolderType folder: ASCFolder) -> [String: Any]? {
        sortInfoOnRootFolderType[String(folder.rootFolderType.rawValue)] as? [String: Any]
            ?? UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any]
    }

    func sortDetails(sortInfo: [String: Any]?) -> (ASCDocumentSortType, sortAscending: Bool) {
        var sortType: ASCDocumentSortType = .dateandtime
        var sortAscending = false
        if let sortInfo {
            if let sortBy = sortInfo[.type] as? String, !sortBy.isEmpty {
                sortType = ASCDocumentSortType(sortBy)
            }

            if let sortOrder = sortInfo[.order] as? String, !sortOrder.isEmpty {
                sortAscending = sortOrder == .ascending
            }
        }
        return (sortType, sortAscending)
    }

    static func setSortInfoOnRootFolderType(folder: ASCFolder, sortInfo: [String: Any]) {
        var sortInfoOnRootFolderType = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] ?? [:]
        sortInfoOnRootFolderType[String(folder.rootFolderType.rawValue)] = sortInfo
        UserDefaults.standard.set(sortInfoOnRootFolderType, forKey: ASCConstants.SettingsKeys.sortDocuments)
    }

    static func buildSortInfo(
        sortState sort: ASCDocumentSortStateType,
        sortType: ASCDocumentSortType,
        sortAscending: Bool
    ) -> [String: Any] {
        var sortAscending = sortAscending
        var sortInfo = [
            String.type: sortType.rawValue,
            String.order: sortAscending ? .ascending : .descending,
        ]

        if sortType != sort.type {
            sortInfo[String.type] = sort.type.rawValue
        } else {
            sortAscending = !sortAscending
            sortInfo[String.order] = sortAscending ? .ascending : .descending
        }
        return sortInfo
    }

    static func buildUIAction(
        sortState sort: ASCDocumentSortStateType,
        sortType: ASCDocumentSortType,
        sortAscending: Bool
    ) -> UIAction {
        if #available(iOS 26.0, *) {
            UIAction(
                title: sort.type.description,
                subtitle: sort.active ? sort.type.subtitle(for: sortAscending) : nil,
                state: sort.active ? .on : .off
            ) { _ in
                let sortInfo = Self.buildSortInfo(sortState: sort, sortType: sortType, sortAscending: sortAscending)
                UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
            }
        } else {
            UIAction(
                title: sort.type.description,
                image: .sortDirectionIcon(isActive: sort.active, sortAscending: sortAscending),
                state: sort.active ? .on : .off
            ) { _ in
                let sortInfo = Self.buildSortInfo(sortState: sort, sortType: sortType, sortAscending: sortAscending)
                UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
            }
        }
    }

    static func buildUIAction(
        sortState sort: ASCDocumentSortStateType,
        sortType: ASCDocumentSortType,
        sortAscending: Bool,
        folder: ASCFolder
    ) -> UIAction {
        if #available(iOS 26.0, *) {
            UIAction(
                title: sort.type.description,
                subtitle: sort.active ? sort.type.subtitle(for: sortAscending) : nil,
                state: sort.active ? .on : .off
            ) { _ in
                let sortInfo = Self.buildSortInfo(sortState: sort, sortType: sortType, sortAscending: sortAscending)
                Self.setSortInfoOnRootFolderType(folder: folder, sortInfo: sortInfo)
            }
        } else {
            UIAction(
                title: sort.type.description,
                image: .sortDirectionIcon(isActive: sort.active, sortAscending: sortAscending),
                state: sort.active ? .on : .off
            ) { _ in
                let sortInfo = Self.buildSortInfo(sortState: sort, sortType: sortType, sortAscending: sortAscending)
                Self.setSortInfoOnRootFolderType(folder: folder, sortInfo: sortInfo)
            }
        }
    }
}

final class CurrentFolderMenu {
    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        let folderType = folder.rootFolderType

        switch folderType {
        case .deviceDocuments, .deviceTrash:
            return CurrentLocalFolderMenu().contextMenu(for: folder, in: viewController)

        case .nextcloudAll,
             .owncloudAll,
             .yandexAll,
             .webdavAll,
             .dropboxAll,
             .googledriveAll,
             .icloudAll,
             .onedriveAll,
             .kdriveAll,

             .common,
             .bunch,
             .trash,
             .user,
             .share,
             .projects,
             .favorites,
             .recent:
            return CurrentCloudFolderMenu().contextMenu(for: folder, in: viewController)

        case .virtualRooms, .roomTemplates:
            return CurrentRoomMenu().contextMenu(for: folder, in: viewController)

        case .archive:
            return CurrentRoomArchivesMenu().contextMenu(for: folder, in: viewController)

        default:
            return UIMenu()
        }
    }

    func actionSheet(for folder: ASCFolder, sender: UIView?, in viewController: ASCDocumentsViewController) -> UIAlertController {
        let folderType = folder.rootFolderType

        switch folderType {
        case .deviceDocuments, .deviceTrash:
            return CurrentLocalFolderMenu().actionSheet(for: folder, sender: sender, in: viewController)

        case .nextcloudAll,
             .owncloudAll,
             .yandexAll,
             .webdavAll,
             .dropboxAll,
             .googledriveAll,
             .icloudAll,
             .onedriveAll,
             .kdriveAll,

             .common,
             .bunch,
             .trash,
             .user,
             .share,
             .projects,
             .favorites,
             .recent:
            return CurrentCloudFolderMenu().actionSheet(for: folder, sender: sender, in: viewController)

        case .virtualRooms:
            return CurrentRoomMenu().actionSheet(for: folder, sender: sender, in: viewController)

        case .archive:
            return CurrentRoomArchivesMenu().actionSheet(for: folder, sender: sender, in: viewController)

        default:
            return UIAlertController()
        }
    }
}

// MARK: Constants

private extension String {
    static let type = "type"
    static let order = "order"
    static let ascending = "ascending"
    static let descending = "descending"
}

private extension UIImage {
    static func sortDirectionIcon(isActive: Bool, sortAscending: Bool) -> UIImage? {
        guard isActive else { return nil }
        return sortAscending
            ? UIImage(systemName: "chevron.up")
            : UIImage(systemName: "chevron.down")
    }
}
