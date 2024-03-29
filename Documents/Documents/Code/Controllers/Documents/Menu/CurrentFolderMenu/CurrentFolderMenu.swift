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

             .onlyofficeCommon,
             .onlyofficeBunch,
             .onlyofficeTrash,
             .onlyofficeUser,
             .onlyofficeShare,
             .onlyofficeProjects,
             .onlyofficeFavorites,
             .onlyofficeRecent:
            return CurrentCloudFolderMenu().contextMenu(for: folder, in: viewController)

        case .onlyofficeRoomShared:
            return CurrentRoomMenu().contextMenu(for: folder, in: viewController)

        case .onlyofficeRoomArchived:
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

             .onlyofficeCommon,
             .onlyofficeBunch,
             .onlyofficeTrash,
             .onlyofficeUser,
             .onlyofficeShare,
             .onlyofficeProjects,
             .onlyofficeFavorites,
             .onlyofficeRecent:
            return CurrentCloudFolderMenu().actionSheet(for: folder, sender: sender, in: viewController)

        case .onlyofficeRoomShared:
            return CurrentRoomMenu().actionSheet(for: folder, sender: sender, in: viewController)

        case .onlyofficeRoomArchived:
            return CurrentRoomArchivesMenu().actionSheet(for: folder, sender: sender, in: viewController)

        default:
            return UIAlertController()
        }
    }
}
