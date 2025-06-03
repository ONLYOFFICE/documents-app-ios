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
                    image: UIImage(systemName: "square.and.pencil")
                ) { [unowned self] action in
                    self.fillForm(file: file)
                }
            )
        }

        /// Preview action

        if actions.contains(.open) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    image: UIImage(systemName: "eye")
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
                    image: UIImage(systemName: "pencil")
                ) { [unowned self] action in
                    self.open(file: file, openMode: .edit)
                }
            )
        }

        /// Download action

        if actions.contains(.download) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.down")
                ) { [unowned self] action in
                    self.download(cell: cell)
                }
            )
        }

        /// Show versions history

        if actions.contains(.showVersionsHistory) {
            shareActions.append(
                UIAction(
                    title: NSLocalizedString("Show version history", comment: ""),
                    image: UIImage(systemName: "clock.arrow.circlepath")
                ) { [unowned self] action in
                    self.showVersionsHistory(file: file)
                })
        }

        ///  Copy shared link action

        if actions.contains(.copySharedLink) {
            shareActions.append(
                UIAction(
                    title: NSLocalizedString("Copy link", comment: ""),
                    image: UIImage(systemName: "link")
                ) { [unowned self] action in
                    self.copySharedLink(file: file)
                }
            )
        }

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

        /// Share action

        if actions.contains(.docspaceShare) {
            shareActions.append(
                UIAction(
                    title: NSLocalizedString("Share", comment: ""),
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [unowned self] action in
                    navigator.navigate(to: .sharedSettingsLink(file: file))
                }
            )
        }

        /// Favorite action

        if actions.contains(.favarite) {
            topActions.append(
                UIAction(
                    title: file.isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as Favorite", comment: "Button title"),
                    image: file.isFavorite
                        ? UIImage(systemName: "star.fill")
                        : UIImage(systemName: "star")
                ) { [unowned self] action in
                    self.favorite(cell: cell, favorite: !file.isFavorite)
                }
            )
        }

        /// Mark as read action

        if actions.contains(.new) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    image: UIImage(systemName: "envelope.open")
                ) { [unowned self] action in
                    self.markAsRead(cell: cell)
                }
            )
        }

        /// Rename action

        if actions.contains(.rename) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: UIImage(systemName: "pencil.and.ellipsis.rectangle")
                ) { [unowned self] action in
                    self.rename(cell: cell)
                }
            )
        }

        // Transform to a room

        if actions.contains(.transformToRoom) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Create room", comment: "Button title"),
                    image: Asset.Images.menuRectanglesAdd.image
                ) { [unowned self] action in
                    transformToRoom(entities: [file])
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc")
        ) { [unowned self] action in
            self.copy(cell: cell)
        }

        /// Duplicate action

        let duplicate = UIAction(
            title: NSLocalizedString("Duplicate", comment: "Button title"),
            image: UIImage(systemName: "plus.rectangle.on.rectangle")
        ) { [unowned self] action in
            self.duplicate(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder")
        ) { [unowned self] action in
            self.move(cell: cell)
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
                    image: UIImage(systemName: "arrow.2.circlepath")
                ) { [unowned self] action in
                    self.recover(cell: cell)
                }
            )
        }

        /// Delete action

        if actions.contains(.delete) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [unowned self] action in
                    self.delete(cell: cell)
                }
            )
        }

        /// Share action

        if actions.contains(.share) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: UIImage(systemName: "person.2")
                ) { [unowned self] action in
                    navigator.navigate(to: .shareSettings(entity: file))
                }
            )
        }

        /// Export action

        if actions.contains(.export) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Export", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [unowned self] action in
                    self.export(cell: cell)
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
                    image: UIImage(systemName: "checkmark.circle")
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
                    image: UIImage(systemName: "arrow.triangle.turn.up.right.circle")
                ) { [weak self] action in

                    guard
                        let self,
                        let index = collectionView.indexPath(for: cell)
                    else { return }

                    self.collectionView(collectionView, didSelectItemAt: index)
                }
            )
        }

        if actions.contains(.shareAsRoom) {
            commonActions.append(
                UIAction(
                    title: NSLocalizedString("Share", comment: ""),
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [unowned self] action in
                    self.showShereFolderAlert(folder: folder)
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
                    image: UIImage(systemName: "envelope.open")
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
                    image: UIImage(systemName: "pencil.and.ellipsis.rectangle")
                ) { [unowned self] action in
                    self.rename(cell: cell)
                }
            )
        }

        /// Edit the room action

        if actions.contains(.edit) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Edit room", comment: "Button title"),
                    image: UIImage(systemName: "gear")
                ) { [unowned self] action in
                    self.editRoom(folder: folder)
                }
            )
        }

        /// Invite users

        if actions.contains(.addUsers) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Invite users", comment: "Button title"),
                    image: UIImage(systemName: "person.badge.plus")
                ) { [unowned self] action in
                    navigator.navigate(to: .addUsers(entity: folder))
                }
            )
        }
        
        /// Create room
        if actions.contains(.createRoom) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Create room", comment: ""),
                    image: Asset.Images.menuRectanglesAdd.image
                ) { [unowned self] action in
                    createRoomFrom(template: folder)
                }
            )
        }
        
        /// Edit template
        if actions.contains(.editTemplate) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Edit template", comment: ""),
                    image: UIImage(systemName: "gear")
                ) { [unowned self] action in
                    editTemplate(template: folder)
                }
            )
        }

        /// Copy general link

        if actions.contains(.link) {
            let title: String

            switch folder.roomType {
            case .public, .custom, .fillingForm:
                title = NSLocalizedString("Copy general link", comment: "Button title")
            default:
                title = NSLocalizedString("Copy link", comment: "Button title")
            }

            basicActions.append(
                UIAction(
                    title: title,
                    image: UIImage(systemName: "link")
                ) { [unowned self] action in
                    self.copyGeneralLinkToClipboard(room: folder)
                }
            )
        }

        /// Info

        if actions.contains(.info) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Info", comment: "Button title"),
                    image: UIImage(systemName: "info.circle")
                ) { [unowned self] action in
                    if folder.isRoom {
                        navigator.navigate(to: .roomSharingLink(folder: folder))
                    } else {
                        navigator.navigate(to: .shareSettings(entity: folder))
                    }
                }
            )
        }

        /// Pin

        if actions.contains(.pin) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Pin to top", comment: "Button title"),
                    image: UIImage(systemName: "pin")
                ) { [unowned self] action in
                    self.pinToggle(cell: cell)
                }
            )
        }

        /// Unpin

        if actions.contains(.unpin) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Unpin", comment: "Button title"),
                    image: UIImage(systemName: "pin.fill")
                ) { [unowned self] action in
                    self.pinToggle(cell: cell)
                }
            )
        }

        /// Share action

        if actions.contains(.share) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: UIImage(systemName: "person.2")
                ) { [unowned self] action in
                    navigator.navigate(to: .shareSettings(entity: folder))
                }
            )
        }

        /// Disable notifications

        if actions.contains(.disableNotifications) {
            basicActions.append(
                UIAction(
                    title: folder.mute
                        ? NSLocalizedString("Enable notifications", comment: "")
                        : NSLocalizedString("Disable notifications", comment: ""),
                    image: folder.mute
                        ? UIImage(systemName: "bell")
                        : UIImage(systemName: "bell.slash")
                ) { [unowned self] action in
                    disableNotifications(room: folder)
                }
            )
        }
        
        /// Save as template
        
        if actions.contains(.saveAsTemplate) {
            basicActions.append(
                UIAction(
                    title: NSLocalizedString("Save as template", comment: ""),
                    image: UIImage(systemName: "note.text.badge.plus")
                ) { [unowned self] action in
                    saveAsTemplate(room: folder)
                }
            )
        }

        // Transfer actions

        var transferActions: [UIMenuElement] = []

        /// Transform to a room

        if actions.contains(.transformToRoom) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Create room", comment: "Button title"),
                    image: Asset.Images.menuRectanglesAdd.image
                ) { [unowned self] action in
                    transformToRoom(entities: [folder])
                }
            )
        }

        /// Duplicate room

        if actions.contains(.duplicate) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Duplicate", comment: ""),
                    image: UIImage(systemName: "doc.on.doc")
                ) { [unowned self] _ in
                    self.duplicateRoom(room: folder)
                }
            )
        }

        /// Download action

        if actions.contains(.download) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.down")
                ) { [unowned self] action in
                    self.download(cell: cell)
                }
            )
        }

        /// Change room owner

        if actions.contains(.changeRoomOwner) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Change room owner", comment: "Button title"),
                    image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                ) { [unowned self] action in
                    self.leaveRoom(cell: cell, folder: folder, changeOwner: true)
                }
            )
        }

        /// Archive

        if actions.contains(.archive) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Move to archive", comment: "Button title"),
                    image: UIImage(systemName: "archivebox")
                ) { [unowned self] action in
                    self.archive(cell: cell, folder: folder)
                }
            )
        }

        if actions.contains(.unarchive) {
            transferActions.append(
                UIAction(
                    title: NSLocalizedString("Move from archive", comment: "Button title"),
                    image: UIImage(systemName: "arrow.up.bin")
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
                    image: UIImage(systemName: "trash")
                ) { [unowned self] action in
                    self.deleteRoomTempateAlert(template: folder) { [weak self] in
                        guard let self else { return }
                        self.deleteRoomTemplate( template: folder)
                    }
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc")
        ) { [unowned self] action in
            self.copy(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder")
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
                    image: UIImage(systemName: "arrow.2.circlepath")
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
                    image: UIImage(systemName: "arrow.right.square")
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
                    image: UIImage(systemName: "trash"),
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
                    image: UIImage(systemName: "trash"),
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
                        navigator.navigate(to: .shareSettings(entity: folder))
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
