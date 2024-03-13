//
//  CurrentNavigationBars.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 13.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentNavigationBars {
    static let shared: CurrentNavigationBars = CurrentNavigationBars()

    func configureToolBar(viewController: ASCDocumentsViewController) -> ASCToolBarType {
        var items: ASCToolBarType = []

        guard let folder = viewController.folder else { return [] }

        let provider = viewController.provider
        let onlyOfficeProvider = provider as? ASCOnlyofficeProvider

        let isRoot = folder.isRoot
        let isRoomList = folder.isRoomListFolder
        let isDevice = (provider?.id == ASCFileManager.localProvider.id)
        let isShared = folder.rootFolderType == .onlyofficeShare
        let isTrash = folder.rootFolderType == .onlyofficeTrash || folder.rootFolderType == .deviceTrash
        let isRecent = onlyOfficeProvider?.category?.folder?.rootFolderType == .onlyofficeRecent
        let isProjectRoot = (folder.rootFolderType == .onlyofficeBunch || folder.rootFolderType == .onlyofficeProjects) && isRoot
        let isGuest = ASCFileManager.onlyofficeProvider?.user?.isVisitor ?? false
        let isPersonalCategory = folder.rootFolderType == .onlyofficeUser
        let isDocSpace = (provider as? ASCOnlyofficeProvider)?.apiClient.serverVersion?.docSpace != nil
        let isDocSpaceArchive = isRoomList && folder.rootFolderType == .onlyofficeRoomArchived
        let isDocSpaceArchiveRoomContent = folder.rootFolderType == .onlyofficeRoomArchived && !isRoot
        let isDocSpaceRoomShared = isRoomList && folder.rootFolderType == .onlyofficeRoomShared
        let isInfoShowing = (isDocSpaceRoomShared || isDocSpaceArchive) && viewController.selectedIds.count <= 1
        let isNeededUpdateToolBarOnSelection = isDocSpaceRoomShared || folder.isRoomListSubfolder
        let isNeededUpdateToolBarOnDeselection = isDocSpaceRoomShared || folder.isRoomListSubfolder
        let isCanRemoveAllRooms = viewController.canRemoveAllItems()

        // Create room
        if isPersonalCategory, isDocSpace {
            items.insert(.createRoom)
        }

        // Move
        if !isTrash, !isDocSpaceArchive, !isDocSpaceArchiveRoomContent, !isDocSpaceRoomShared, isDevice || !(isShared || isProjectRoot || isGuest) {
            items.insert(.move)
        }

        // Copy
        if !isTrash, !isRoomList {
            items.insert(.copy)
        }

        // Restore
        if isTrash {
            items.insert(.restore)
        }

        // Restore room
        if isDocSpaceArchive, folder.security.move {
            items.insert(.restoreRoom)
        }

        // Remove from list
        if isShared {
            items.insert(.removeFromList)
        }

        // Remove
        if isDevice || !(isShared || isProjectRoot || isGuest || isRecent || isDocSpaceRoomShared || isDocSpaceArchiveRoomContent || isDocSpaceArchive) {
            items.insert(.remove)
        }

        // Info
        if isInfoShowing {
            items.insert(.info)
        }

        // Pin
        if isDocSpaceRoomShared {
            items.insert(.pin)
        }

        // Archive
        if isDocSpaceRoomShared {
            items.insert(.archive)
        }

        // Remove all
        if isTrash {
            items.insert(.removeAll)
        }

        // Unarchive
        if isDocSpaceArchive {
            items.insert(.unarchive)
        }

        // Remove all rooms
        if isDocSpaceArchive, isCanRemoveAllRooms {
            items.insert(.removeAllRooms)
        }

        if isNeededUpdateToolBarOnSelection {
            items.insert(.neededUpdateToolBarOnSelection)
        }

        if isNeededUpdateToolBarOnDeselection {
            items.insert(.neededUpdateToolBarOnDeselection)
        }

        return items
    }
}
