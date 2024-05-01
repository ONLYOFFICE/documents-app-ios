//
//  FolderNavigationBarActionsConfigurator.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 13.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class FolderNavigationBarActionsConfigurator {
    var viewController: ASCDocumentsViewController!

    init(viewController: ASCDocumentsViewController) {
        self.viewController = viewController
    }

    func configureFolderActionsToolBar() -> ASCToolBarType {
        var actions: ASCToolBarType = []

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
            actions.insert(.createRoom)
        }

        // Move
        if !isTrash, !isDocSpaceArchive, !isDocSpaceArchiveRoomContent, !isDocSpaceRoomShared, isDevice || !(isShared || isProjectRoot || isGuest) {
            actions.insert(.move)
        }

        // Copy
        if !isTrash, !isRoomList {
            actions.insert(.copy)
        }

        // Restore
        if isTrash {
            actions.insert(.restore)
        }

        // Restore room
        if isDocSpaceArchive, folder.security.move {
            actions.insert(.restoreRoom)
        }

        // Remove from list
        if isShared {
            actions.insert(.removeFromList)
        }

        // Remove
        if isDevice || !(isShared || isProjectRoot || isGuest || isRecent || isDocSpaceRoomShared || isDocSpaceArchiveRoomContent || isDocSpaceArchive) {
            actions.insert(.remove)
        }

        // Info
        if isInfoShowing {
            actions.insert(.info)
        }

        // Pin
        if isDocSpaceRoomShared {
            actions.insert(.pin)
        }

        // Archive
        if isDocSpaceRoomShared {
            actions.insert(.archive)
        }

        // Remove all
        if isTrash {
            actions.insert(.removeAll)
        }

        // Unarchive
        if isDocSpaceArchive {
            actions.insert(.unarchive)
        }

        // Remove all rooms
        if isDocSpaceArchive, isCanRemoveAllRooms {
            actions.insert(.removeAllRooms)
        }

        if isNeededUpdateToolBarOnSelection {
            actions.insert(.neededUpdateToolBarOnSelection)
        }

        if isNeededUpdateToolBarOnDeselection {
            actions.insert(.neededUpdateToolBarOnDeselection)
        }

        return actions
    }
}
