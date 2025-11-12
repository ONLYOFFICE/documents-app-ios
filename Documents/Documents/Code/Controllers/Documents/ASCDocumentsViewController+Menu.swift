//
//  ASCDocumentsViewController+Menu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 22.08.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

extension ASCDocumentsViewController {
    // MARK: - Item context menu

    func buildFileContextMenu(for cell: ASCFileViewCell) -> UIMenu? {
        guard
            let file = cell.entity as? ASCFile,
            let provider
        else { return nil }

        let actions = provider.actions(for: file)

        var rootActions: [UIMenuElement] = []
        var topActions: [UIMenuElement] = []
        var shareActions: [UIMenuElement] = []
        var middleActions: [UIMenuElement] = []
        var bottomActions: [UIMenuElement] = []

        /// Fill pdf form

        if actions.contains(.fillForm) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Fill", comment: "Fill form Button title"),
                    image: Asset.Images.pencilAndRectangle.image
                ) { [unowned self] action in
                    self.fillForm(file: file)
                }
            )
        }

        /// Fill pdf form

        if actions.contains(.startFilling) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Start filling", comment: "Start filling form Button title"),
                    image: Asset.Images.pencilAndRectangle.image
                ) { [unowned self] action in
                    self.startFilling(file: file)
                }
            )
        }

        /// Filling status form

        if actions.contains(.fillingStatus) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Filling Status", comment: "Start filling form Button title"),
                    image: Asset.Images.chartBar.image
                ) { [unowned self] action in
                    self.fillingStatus(file: file)
                }
            )
        }

        /// Preview action

        if actions.contains(.open) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    image: Asset.Images.eye.image
                ) { [unowned self] action in
                    self.open(file: file, openMode: .view)
                }
            )
        }

        /// Edit action

        if actions.contains(.edit) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Edit", comment: "Button title"),
                    image: Asset.Images.pencil.image
                ) { [unowned self] action in
                    self.open(file: file, openMode: .edit)
                }
            )
        }

        /// Copy shared link
        let copySharedLink = UIAction(
            title: NSLocalizedString("Copy shared link", comment: ""),
            image: Asset.Images.link.image
        ) { [unowned self] action in
            self.copySharedLink(file: file)
        }

        /// Share action

        let sharingSettings = UIAction(
            title: NSLocalizedString("Share", comment: ""),
            image: Asset.Images.squareAndArrowUp.image
        ) { [unowned self] action in
            navigator.navigate(to: .sharedSettingsLink(file: file))
        }

        /// Tranfrorm to room
        let createRoom = UIAction(
            title: NSLocalizedString("Create room", comment: "Button title"),
            image: Asset.Images.menuRectanglesAdd.image
        ) { [unowned self] action in
            transformToRoom(entities: [file])
        }

        if actions.contains(.copySharedLink), actions.contains(.docspaceShare) {
            var menuChildren: [UIMenuElement] = [copySharedLink, sharingSettings]

            if actions.contains(.createRoom) {
                menuChildren.append(createRoom)
            }
            shareActions.append(UIMenu(title: NSLocalizedString("Share", comment: ""), children: menuChildren))
        }

        /// Show versions history

        if actions.contains(.showVersionsHistory) {
            shareActions.append(
                UIAction(
                    title: NSLocalizedString("Show version history", comment: ""),
                    image: Asset.Images.clockArrowCirclepath.image
                ) { [unowned self] action in
                    self.showVersionsHistory(file: file)
                })
        }

//        if actions.contains(.openLocation) {
//            shareActions.append(
//                UIAction(
//                    title: NSLocalizedString("Open location", comment: ""),
//                    image: Asset.Images.menuOpenLocation.image
//                ) { [unowned self] _ in
//
//                }
//            )
//        }

        /// Custom filter

        if actions.contains(.setCustomFilter) {
            shareActions.append(
                UIAction(
                    title: file.customFilterEnabled
                        ? NSLocalizedString("Disable Custom filter", comment: "")
                        : NSLocalizedString("Enable Custom filter", comment: ""),
                    image: Asset.Images.menuCustomFilter.image
                ) { [unowned self] action in
                    self.setCustomFilter(cell: cell, file: file)
                }
            )
        }

        /// Mark as read action

        if actions.contains(.new) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    image: Asset.Images.envelopeOpen.image
                ) { [unowned self] action in
                    self.markAsRead(cell: cell)
                }
            )
        }

        /// Favorite action

        if actions.contains(.favarite) {
            middleActions.append(
                UIAction(
                    title: file.isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as Favorite", comment: "Button title"),
                    image: file.isFavorite
                        ? Asset.Images.menuRemoveFromFavorites.image
                        : Asset.Images.menuMarkAsFavorite.image
                ) { [unowned self] action in
                    self.favorite(cell: cell, favorite: !file.isFavorite)
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: Asset.Images.listMenuCopy.image
        ) { [unowned self] action in
            self.copy(cell: cell)
        }

        /// Duplicate action

        let duplicate = UIAction(
            title: NSLocalizedString("Duplicate", comment: "Button title"),
            image: Asset.Images.plusRectangleOnRectangle.image
        ) { [unowned self] action in
            self.duplicate(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: Asset.Images.folder.image
        ) { [unowned self] action in
            self.move(cell: cell)
        }

        /// Download action

        if actions.contains(.download) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: Asset.Images.squareAndArrowDown.image
                ) { [unowned self] action in
                    self.download(cell: cell)
                }
            )
        }

        /// Transfer items

        if actions.contains(.copy), actions.contains(.duplicate), actions.contains(.move) {
            middleActions.append(
                UIMenu(title: NSLocalizedString("Move or Copy", comment: "Button title") + "...", children: [copy, duplicate, move])
            )
        } else {
            if actions.contains(.copy) {
                middleActions.append(copy)
            }
            if actions.contains(.duplicate) {
                middleActions.append(duplicate)
            }
            if actions.contains(.move) {
                middleActions.append(move)
            }
        }

        /// Restore action

        if actions.contains(.restore) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Restore", comment: "Button title"),
                    image: Asset.Images.trashSlash.image
                ) { [unowned self] action in
                    self.recover(cell: cell)
                }
            )
        }

        /// Export action

        if actions.contains(.export) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Export", comment: "Button title"),
                    image: Asset.Images.squareAndArrowUp.image
                ) { [unowned self] action in
                    self.export(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: Asset.Images.trash.image,
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        /// Rename action

        if actions.contains(.rename) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: Asset.Images.pencilAndEllipsisRectangle.image
                ) { [unowned self] action in
                    self.rename(cell: cell)
                }
            )
        }

        /// Share action

        if actions.contains(.share) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: Asset.Images.person2.image
                ) { [unowned self] action in
                    navigator.navigate(to: .shareSettings(entity: file))
                }
            )
        }

        /// Delete action

        if actions.contains(.delete) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: Asset.Images.trash.image,
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        if #available(iOS 14.0, *) {
            return UIMenu(title: "", options: [.displayInline], children: [
                UIMenu(title: "", options: .displayInline, children: topActions),
                UIMenu(title: "", options: .displayInline, children: shareActions),
                UIMenu(title: "", options: .displayInline, children: middleActions),
                UIMenu(title: "", options: .displayInline, children: bottomActions),
            ])
        } else {
            rootActions = [topActions, shareActions, bottomActions, middleActions].reduce([], +)
            return UIMenu(title: "", children: rootActions)
        }
    }

    func buildFolderContextMenu(for cell: ASCFolderViewCell) -> UIMenu? {
        guard
            let folder = cell.entity as? ASCFolder,
            let provider
        else { return nil }
        let actions = provider.actions(for: folder)

        // Common actions

        var commonActions: [UIMenuElement] = []

        if actions.contains(.select) {
            commonActions.append(
                UIAction(
                    title: NSLocalizedString("Select", comment: "Button title"),
                    image: Asset.Images.checkmarkCircle.image
                ) { [weak self] action in
                    self?.setEditMode(true)

                    if let index = self?.collectionView.indexPath(for: cell) {
                        self?.collectionView.selectItem(
                            at: index,
                            animated: true,
                            scrollPosition: .centeredHorizontally
                        )
                        self?.updateSelectedItems(indexPath: index)
                    }
                }
            )
        }

        if actions.contains(.open), !collectionView.isEditing {
            commonActions.append(
                UIAction(
                    title: NSLocalizedString("Open", comment: "Button title"),
                    image: Asset.Images.arrowUpRightSquare.image
                ) { [weak self] action in
                    guard
                        let self,
                        let index = collectionView.indexPath(for: cell)
                    else { return }

                    self.collectionView(collectionView, didSelectItemAt: index)
                }
            )
        }

        /// Pin

        if actions.contains(.pin) {
            commonActions.append(
                UIAction(
                    title: NSLocalizedString("Pin to top", comment: "Button title"),
                    image: Asset.Images.pin.image
                ) { [unowned self] action in
                    self.pinToggle(cell: cell)
                }
            )
        }

        /// Unpin

        if actions.contains(.unpin) {
            commonActions.append(
                UIAction(
                    title: NSLocalizedString("Unpin", comment: "Button title"),
                    image: Asset.Images.pinFill.image
                ) { [unowned self] action in
                    self.pinToggle(cell: cell)
                }
            )
        }

        /// Disable notifications

        if actions.contains(.disableNotifications) {
            commonActions.append(
                UIAction(
                    title: folder.mute
                        ? NSLocalizedString("Enable notifications", comment: "")
                        : NSLocalizedString("Disable notifications", comment: ""),
                    image: folder.mute
                        ? Asset.Images.bell.image
                        : Asset.Images.bellSlash.image
                ) { [unowned self] action in
                    Task { @MainActor in
                        await disableNotifications(room: folder)
                    }
                }
            )
        }

        // Basic actions

        var basicActions: [UIMenuElement] = []

        /// Mark as read action

        if actions.contains(.new) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    image: Asset.Images.envelopeOpen.image
                ) { [unowned self] action in
                    self.markAsRead(cell: cell)
                }
            )
        }

        /// Rename

        if actions.contains(.rename) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: Asset.Images.pencilAndEllipsisRectangle.image
                ) { [unowned self] action in
                    self.rename(cell: cell)
                }
            )
        }

        // Manage room submenu

        /// Edit the room action

        let editRoomAction = UIAction(
            title: NSLocalizedString("Edit room", comment: "Button title"),
            image: Asset.Images.gear.image
        ) { [unowned self] _ in
            self.editRoom(folder: folder)
        }

        /// Save as template

        let saveAsTemplate = UIAction(
            title: NSLocalizedString("Save as template", comment: ""),
            image: Asset.Images.rectangleStackBadgePlus.image
        ) { [unowned self] _ in
            self.saveAsTemplate(room: folder)
        }

        /// Duplicate room

        let duplicateRoom = UIAction(
            title: NSLocalizedString("Duplicate", comment: ""),
            image: Asset.Images.plusRectangleOnRectangle.image
        ) { [unowned self] _ in
            Task { @MainActor in
                await self.duplicateRoom(room: folder)
            }
        }

        /// Download

        let downloadRoom = UIAction(
            title: NSLocalizedString("Download", comment: "Button title"),
            image: Asset.Images.squareAndArrowDown.image
        ) { [unowned self] _ in
            self.download(cell: cell)
        }

        /// Change room owner
        let changeRoomOwner = UIAction(
            title: NSLocalizedString("Change room owner", comment: "Button title"),
            image: Asset.Images.arrow2Circlepath.image
        ) { [unowned self] action in
            self.leaveRoom(cell: cell, folder: folder, changeOwner: true)
        }

        if actions.contains(.edit),
           actions.contains(.saveAsTemplate),
           actions.contains(.download),
           actions.contains(.duplicate)
        {
            var children: [UIMenuElement] = [editRoomAction, saveAsTemplate, downloadRoom, duplicateRoom]

            if actions.contains(.changeRoomOwner) {
                children.append(changeRoomOwner)
            }

            let manageMenu = UIMenu(title: NSLocalizedString("Manage", comment: "Button title"), children: children)
            basicActions.append(manageMenu)
        }

        /// Edit template

        if actions.contains(.editTemplate) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Edit template", comment: ""),
                    image: Asset.Images.gear.image
                ) { [unowned self] action in
                    editTemplate(template: folder)
                }
            )
        }

        // Share submenu

        /// Invite users

        let inviteUsers = UIAction(
            title: NSLocalizedString("Invite users", comment: "Button title"),
            image: Asset.Images.personBadgePlus.image
        ) { [unowned self] action in
            navigator.navigate(to: .addUsers(entity: folder))
        }

        /// Copy  link

        let title: String

        switch folder.roomType {
        case .public, .custom, .fillingForm:
            title = NSLocalizedString("Copy shared link", comment: "Button title")
        default:
            title = NSLocalizedString("Copy link", comment: "Button title")
        }
        let copyLink = UIAction(
            title: title,
            image: Asset.Images.link.image
        ) { [unowned self] action in
            self.copyGeneralLinkToClipboard(room: folder)
        }

        /// Share action

        let share = UIAction(
            title: NSLocalizedString("Sharing Settings", comment: "Button title"),
            image: Asset.Images.person2.image
        ) { [unowned self] _ in
            navigator.navigate(to: .shareSettings(entity: folder))
        }

        /// Create room

        let createRoom = UIAction(
            title: NSLocalizedString("Create room", comment: ""),
            image: Asset.Images.menuRectanglesAdd.image
        ) { [unowned self] action in
            createRoomFrom(template: folder)
        }

        if actions.contains(.link), actions.contains(.share) {
            var shareMenuElements: [UIMenuElement] = [copyLink, share]

            if actions.contains(.addUsers) {
                shareMenuElements.append(inviteUsers)
            }

            if actions.contains(.createRoom) || actions.contains(.shareAsRoom) {
                shareMenuElements.append(createRoom)
            }
            basicActions.append(
                UIMenu(title: NSLocalizedString("Share", comment: "Button title"), children: shareMenuElements)
            )
        }

        /// Info

        if actions.contains(.info) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Info", comment: "Button title"),
                    image: Asset.Images.infoCircle.image
                ) { [unowned self] action in
                    if folder.isRoom {
                        navigator.navigate(to: .roomSharingLink(folder: folder))
                    } else {
                        navigator.navigate(to: .shareSettings(entity: folder))
                    }
                }
            )
        }

        // Transfer actions

        var transferActions: [UIMenuElement] = []

        if actions.contains(.transformToRoom), actions.contains(.link), folder.isRoom {
            var childrenMenu: [UIMenuElement] = [copyLink, share]
            if actions.contains(.share) {
                childrenMenu.append(share)
            }
            transferActions.append(
                UIMenu(title: NSLocalizedString("Share", comment: ""), children: childrenMenu)
            )
        }

        /// Duplicate room

        let duplicate = UIAction(
            title: NSLocalizedString("Duplicate", comment: ""),
            image: Asset.Images.listMenuCopy.image
        ) { [unowned self] _ in
            Task { @MainActor in
                await self.duplicateRoom(room: folder)
            }
        }

        /// Download

        let download = UIAction(
            title: NSLocalizedString("Download", comment: "Button title"),
            image: Asset.Images.squareAndArrowDown.image
        ) { [unowned self] _ in
            self.download(cell: cell)
        }

        if actions.contains(.duplicate),
           actions.contains(.download),
           !folder.isRoom
        {
            basicActions.append(
                UIMenu(title: NSLocalizedString("Manage", comment: "Button title"), children: [duplicate, download])
            )
        }

        /// Archive

        if actions.contains(.archive) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Move to archive", comment: "Button title"),
                    image: Asset.Images.archivebox.image
                ) { [unowned self] action in
                    self.archive(cell: cell, folder: folder)
                }
            )
        }

        if actions.contains(.unarchive) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Move from archive", comment: "Button title"),
                    image: Asset.Images.trashSlash.image
                ) { [unowned self] action in
                    self.showRestoreRoomAlert { [weak self] in
                        guard let self else { return }
                        self.unarchive(cell: cell, folder: folder)
                    }
                }
            )
        }

        if actions.contains(.deleteRoomTemplate) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Delete template", comment: "Button title"),
                    image: Asset.Images.trash.image,
                    attributes: [.destructive]
                ) { [unowned self] action in
                    self.deleteRoomTempateAlert(template: folder) { [weak self] in
                        guard let self else { return }
                        self.deleteRoomTemplate(template: folder)
                    }
                }
            )
        }

        if actions.contains(.favarite) {
            let isFavorite = folder.isFavorite ?? false
            transferActions.append(
                UIAction(
                    title: isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as Favorite", comment: "Button title"),
                    image: isFavorite
                        ? Asset.Images.menuRemoveFromFavorites.image
                        : Asset.Images.menuMarkAsFavorite.image
                ) { [unowned self] action in
                    self.favorite(cell: cell, favorite: !isFavorite)
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: Asset.Images.listMenuCopy.image
        ) { [unowned self] action in
            self.copy(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: Asset.Images.folder.image
        ) { [unowned self] action in
            self.move(cell: cell)
        }

        /// Transfer items

        if actions.contains(.copy), actions.contains(.move) {
            transferActions.append(
                UIMenu(title: NSLocalizedString("Move or Copy", comment: "Button title") + "...", children: [copy, move])
            )
        } else {
            if actions.contains(.copy) {
                transferActions.append(copy)
            }
            if actions.contains(.move) {
                transferActions.append(move)
            }
        }

        /// Restore action

        if actions.contains(.restore) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Restore", comment: "Button title"),
                    image: Asset.Images.trashSlash.image
                ) { [unowned self] action in
                    self.recover(cell: cell)
                }
            )
        }

        /// Leave the room action

        if actions.contains(.leave) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Leave the room", comment: "Button title"),
                    image: Asset.Images.arrowRightSquare.image
                ) { [unowned self] action in
                    self.leaveRoom(cell: cell, folder: folder)
                }
            )
        }

        /// Delete action

        if actions.contains(.delete) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: Asset.Images.trash.image,
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount), !(self.folder?.isThirdParty ?? false) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: Asset.Images.trash.image,
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        let commonMenu = UIMenu(title: "", options: .displayInline, children: commonActions)
        let basicMenu = UIMenu(title: "", options: .displayInline, children: basicActions)
        let transferMenu = UIMenu(title: "", options: .displayInline, children: transferActions)

        let menus: [UIMenuElement] = [commonMenu, basicMenu, transferMenu]

        return UIMenu(title: "", options: [.displayInline], children: menus)
    }

    // MARK: - Cell menu

    func buildCellMenu(for cell: ASCEntityViewCellProtocol) -> [UIContextualAction] {
        if let fileCell = cell as? ASCFileViewCell {
            return buildFileCellMenu(for: fileCell)
        } else if let folderCell = cell as? ASCFolderViewCell {
            return buildFolderCellMenu(for: folderCell)
        }
        return []
    }

    func buildFileCellMenu(for cell: ASCFileViewCell) -> [UIContextualAction] {
        guard
            let file = cell.entity as? ASCFile,
            let provider,
            view.isUserInteractionEnabled
        else { return [] }

        let actions = provider.actions(for: file)

        // Restore
        let restore = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.recover(cell: cell)
            actionPerformed(true)
        }
        restore.image = swipeLayout(icon: Asset.Images.listMenuRestore.image, text: NSLocalizedString("Restore", comment: "Button title"))
        restore.backgroundColor = ASCConstants.Colors.grey

        // Delete
        let delete = UIContextualAction(style: .destructive, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }

            self.deleteIfNeeded(cell: cell, menuButton: cell) { cell, allowDelete in
                if allowDelete {
                    self.delete(cell: cell)
                }
            }

            actionPerformed(true)
        }
        delete.image = swipeLayout(icon: Asset.Images.listMenuTrash.image, text: NSLocalizedString("Delete", comment: "Button title"))
        delete.backgroundColor = ASCConstants.Colors.red

        // Download
        let download = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.download(cell: cell)
            actionPerformed(true)
        }
        download.image = swipeLayout(icon: Asset.Images.listMenuDownload.image, text: NSLocalizedString("Download", comment: "Button title"))
        download.backgroundColor = ASCConstants.Colors.grey

        // Rename
        let rename = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.rename(cell: cell)
            actionPerformed(true)
        }
        rename.image = swipeLayout(icon: Asset.Images.listMenuRename.image, text: NSLocalizedString("Rename", comment: "Button title"))
        rename.backgroundColor = ASCConstants.Colors.grey

        // Copy
        let copy = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.copy(cell: cell)
            actionPerformed(true)
        }
        copy.image = swipeLayout(icon: Asset.Images.listMenuCopy.image, text: NSLocalizedString("Copy", comment: "Button title"))
        copy.backgroundColor = ASCConstants.Colors.grey

        // More
        let more = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }
            self.more(cell: cell, menuButton: cell)
            actionPerformed(true)
        }
        more.image = swipeLayout(icon: Asset.Images.listMenuMore.image, text: NSLocalizedString("More", comment: "Button title"))
        more.backgroundColor = ASCConstants.Colors.lightGrey

        var items: [UIContextualAction] = []

        if actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore) { items.append(restore) }
        if actions.contains(.rename) { items.append(rename) }
        if actions.contains(.copy) { items.append(copy) }
        if actions.contains(.download) { items.append(download) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return items
    }

    func buildFolderCellMenu(for cell: ASCFolderViewCell) -> [UIContextualAction] {
        guard
            let folder = cell.entity as? ASCFolder,
            let provider,
            view.isUserInteractionEnabled
        else { return [] }

        let actions = provider.actions(for: folder)

        // Restore
        let restore = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.recover(cell: cell)
            actionPerformed(true)
        }
        restore.image = swipeLayout(icon: Asset.Images.listMenuRestore.image, text: NSLocalizedString("Restore", comment: "Button title"))
        restore.backgroundColor = ASCConstants.Colors.grey

        // Delete
        let delete = UIContextualAction(style: .destructive, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }

            self.deleteIfNeeded(cell: cell, menuButton: cell) { cell, allowDelete in
                if allowDelete {
                    self.delete(cell: cell)
                }
            }

            actionPerformed(true)
        }
        delete.image = swipeLayout(icon: Asset.Images.listMenuTrash.image, text: NSLocalizedString("Delete", comment: "Button title"))
        delete.backgroundColor = ASCConstants.Colors.red

        // Rename
        let rename = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.rename(cell: cell)
            actionPerformed(true)
        }
        rename.image = swipeLayout(icon: Asset.Images.listMenuRename.image, text: NSLocalizedString("Rename", comment: "Button title"))
        rename.backgroundColor = ASCConstants.Colors.grey

        // Copy
        let copy = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            self.copy(cell: cell)
            actionPerformed(true)
        }
        copy.image = swipeLayout(icon: Asset.Images.listMenuCopy.image, text: NSLocalizedString("Copy", comment: "Button title"))
        copy.backgroundColor = ASCConstants.Colors.grey

        // More
        let more = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }
            self.more(cell: cell, menuButton: cell)
            actionPerformed(true)
        }
        more.image = swipeLayout(icon: Asset.Images.listMenuMore.image, text: NSLocalizedString("More", comment: "Button title"))
        more.backgroundColor = ASCConstants.Colors.lightGrey

        // Archive
        let archive = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }
            self.archive(cell: cell, folder: folder)
            actionPerformed(true)
        }
        archive.image = swipeLayout(icon: Asset.Images.categoryArchived.image.withTintColor(.white), text: NSLocalizedString("Archive", comment: "Button title"))
        archive.backgroundColor = Asset.Colors.brend.color

        // Info
        let info = UIContextualAction(style: .normal, title: nil) { [unowned self] action, sourceView, actionPerformed in
            guard view.isUserInteractionEnabled else { return }
            navigator.navigate(to: .shareSettings(entity: folder))
            actionPerformed(true)
        }
        info.image = swipeLayout(icon: Asset.Images.barInfo.image.withTintColor(.white), text: NSLocalizedString("Info", comment: "Button title"))
        info.backgroundColor = ASCConstants.Colors.lighterGrey

        var items: [UIContextualAction] = []

        if actions.contains(.unmount) || actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore) { items.append(restore) }
        if actions.contains(.rename) { items.append(rename) }
        if actions.contains(.copy) { items.append(copy) }
        if actions.contains(.archive) { items.append(archive) }
        if actions.contains(.info) { items.append(info) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return items
    }

    // MARK: - Action menu

    func buildActionMenu(for cell: UICollectionViewCell) -> UIAlertController? {
        if cell is ASCFileViewCell {
            return buildFileActionMenu(for: cell)
        } else if cell is ASCFolderViewCell {
            return buildFolderActionMenu(for: cell)
        }
        return nil
    }

    func buildFileActionMenu(for cell: UICollectionViewCell) -> UIAlertController? {
        guard
            let cell = cell as? ASCFileViewCell,
            let file = cell.entity as? ASCFile,
            let provider,
            view.isUserInteractionEnabled
        else { return nil }

        let actions = provider.actions(for: file)

        let actionAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        if actions.contains(.fillForm) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Fill", comment: "Fill form Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.fillForm(file: file)
                    }
                )
            )
        }

        if actions.contains(.open) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.open(file: file, openMode: .view)
                    }
                )
            )
        }

        if actions.contains(.edit) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Edit", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.open(file: file, openMode: .edit)
                    }
                )
            )
        }

        if actions.contains(.download) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.download(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.showVersionsHistory) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Show version history", comment: ""),
                    style: .default,
                    handler: { [unowned self] _ in
                        self.showVersionsHistory(file: file)
                    }
                ))
        }

//        if actions.contains(.openLocation) {
//            actionAlertController.addAction(
//                UIAlertAction(
//                    title: NSLocalizedString("Open location", comment: ""),
//                    style: .default,
//                    handler: { [unowned self] _ in
//
//                    }
//                )
//            )
//        }

        if actions.contains(.rename) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.rename(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.copy) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Copy", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.copy(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.duplicate) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Duplicate", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.duplicate(cell: cell)
                    }
                ))
        }

        if actions.contains(.move) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Move", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.move(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.favarite) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: file.isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as Favorite", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.favorite(cell: cell, favorite: !file.isFavorite)
                    }
                )
            )
        }

        if actions.contains(.new) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.markAsRead(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.share) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        navigator.navigate(to: .shareSettings(entity: file))
                    }
                )
            )
        }

        if actions.contains(.export) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Export", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.export(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.delete) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        self.delete(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.unmount) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        self.delete(cell: cell)
                    }
                )
            )
        }

        if UIDevice.phone {
            actionAlertController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: { action in
                    }
                )
            )
        }

        return actionAlertController
    }

    func buildFolderActionMenu(for cell: UICollectionViewCell) -> UIAlertController? {
        guard
            let cell = cell as? ASCFolderViewCell,
            let folder = cell.entity as? ASCFolder,
            let provider,
            view.isUserInteractionEnabled
        else { return nil }

        let actions = provider.actions(for: folder)

        let actionAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        if actions.contains(.rename) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.rename(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.pin) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Pin to top", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.pinToggle(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.unpin) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Unpin", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.pinToggle(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.archive) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Archive", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.archive(cell: cell, folder: folder)
                    }
                )
            )
        }

        if actions.contains(.unarchive) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Move from archive", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.archive(cell: cell, folder: folder)
                    }
                )
            )
        }

        if actions.contains(.copy) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Copy", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.copy(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.move) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Move", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.move(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.favarite) {
            let isFavorite = folder.isFavorite ?? false
            actionAlertController.addAction(
                UIAlertAction(
                    title: isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as Favorite", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.favorite(cell: cell, favorite: !isFavorite)
                    }
                )
            )
        }

        if actions.contains(.new) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        self.markAsRead(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.addUsers) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Add users", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        navigator.navigate(to: .addUsers(entity: folder))
                    }
                )
            )
        }

        if actions.contains(.info) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Info", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        navigator.navigate(to: .shareSettings(entity: folder))
                    }
                )
            )
        }

        if actions.contains(.delete) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        self.delete(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.unmount), !(self.folder?.isThirdParty ?? false) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        self.delete(cell: cell)
                    }
                )
            )
        }

        if UIDevice.phone {
            actionAlertController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: { action in
                    }
                )
            )
        }

        return actionAlertController
    }

    private func swipeLayout(icon: UIImage, text: String) -> UIImage {
        let canvasSize = CGSize(width: 60, height: 60)
        let img = icon.withTintColor(.white, renderingMode: .alwaysOriginal)

        let imageView = UIImageView(frame: .init(x: 0, y: 8, width: canvasSize.width, height: canvasSize.height * 0.4))
        imageView.image = img
        imageView.contentMode = .center

        let label = UILabel(frame: .init(x: 0, y: canvasSize.height * 0.5 + 5, width: canvasSize.width, height: canvasSize.height * 0.5 - 5))
        label.font = UIFont.preferredFont(forTextStyle: .caption1).bold()
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.text = text

        let tempView = UIView(frame: CGRect(origin: .zero, size: canvasSize))
        tempView.addSubview(imageView)
        tempView.addSubview(label)

        let renderer = UIGraphicsImageRenderer(bounds: tempView.bounds)
        let image = renderer.image { rendererContext in
            tempView.layer.render(in: rendererContext.cgContext)
        }
        return image
    }
}
