//
//  ASCDocumentsViewController+Menu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 22.08.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import MGSwipeTableCell
import UIKit

extension ASCDocumentsViewController {
    // MARK: - Item context menu

    @available(iOS 13.0, *)
    func buildFileContextMenu(for cell: ASCFileCell) -> UIMenu? {
        guard
            let file = cell.file,
            let provider = provider
        else {
            return nil
        }

        let actions = provider.actions(for: file)

        var rootActions: [UIMenuElement] = []
        var topActions: [UIMenuElement] = []
        var middleActions: [UIMenuElement] = []
        var bottomActions: [UIMenuElement] = []

        /// Preview action

        if actions.contains(.open) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    image: UIImage(systemName: "eye")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.open(file: file, viewMode: true)
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
                    cell.hideSwipe(animated: true)
                    self.open(file: file)
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
                    cell.hideSwipe(animated: true)
                    self.download(cell: cell)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
                    self.rename(cell: cell)
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc")
        ) { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.copy(cell: cell)
        }

        /// Duplicate action

        let duplicate = UIAction(
            title: NSLocalizedString("Duplicate", comment: "Button title"),
            image: UIImage(systemName: "plus.rectangle.on.rectangle")
        ) { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.duplicate(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder")
        ) { [unowned self] action in
            cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
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
                    cell.hideSwipe(animated: true)
                    self.export(cell: cell)
                }
            )
        }

        if #available(iOS 14.0, *) {
            return UIMenu(title: "", options: [.displayInline], children: [
                UIMenu(title: "", options: .displayInline, children: topActions),
                UIMenu(title: "", options: .displayInline, children: middleActions),
                UIMenu(title: "", options: .displayInline, children: bottomActions),
            ])
        } else {
            rootActions = [topActions, bottomActions, middleActions].reduce([], +)
            return UIMenu(title: "", children: rootActions)
        }
    }

    @available(iOS 13.0, *)
    func buildFolderContextMenu(for cell: ASCFolderCell) -> UIMenu? {
        guard
            let folder = cell.folder,
            let provider = provider
        else {
            return nil
        }
        let actions = provider.actions(for: folder)

        var rootActions: [UIMenuElement] = []

        /// Rename action

        if actions.contains(.rename) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: UIImage(systemName: "pencil.and.ellipsis.rectangle")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.rename(cell: cell)
                }
            )
        }

        if actions.contains(.pin) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Pin to top", comment: "Button title"),
                    image: UIImage(systemName: "pin")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.pinToggle(cell: cell)
                }
            )
        }

        if actions.contains(.unpin) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Unpin", comment: "Button title"),
                    image: UIImage(systemName: "pin.slash")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.pinToggle(cell: cell)
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc")
        ) { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.copy(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder")
        ) { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.move(cell: cell)
        }

        /// Transfer items

        if actions.contains(.copy), actions.contains(.move) {
            rootActions.append(
                UIMenu(title: NSLocalizedString("Move or Copy", comment: "Button title") + "...", children: [copy, move])
            )
        } else {
            if actions.contains(.copy) {
                rootActions.append(copy)
            }
            if actions.contains(.move) {
                rootActions.append(move)
            }
        }

        /// Share action

        if actions.contains(.share) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: UIImage(systemName: "person.2")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    navigator.navigate(to: .shareSettings(entity: folder))
                }
            )
        }

        /// Mark as read action

        if actions.contains(.new) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Mark as Read", comment: "Button title"),
                    image: UIImage(systemName: "envelope.open")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.markAsRead(cell: cell)
                }
            )
        }

        /// Restore action

        if actions.contains(.restore) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Restore", comment: "Button title"),
                    image: UIImage(systemName: "arrow.2.circlepath")
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.recover(cell: cell)
                }
            )
        }

        /// Delete action

        if actions.contains(.delete) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount), !(self.folder?.isThirdParty ?? false) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        return UIMenu(title: "", children: rootActions)
    }

    // MARK: - Cell menu

    func buildFileCellMenu(for cell: ASCFileCell) -> [MGSwipeButton]? {
        guard
            let file = cell.file,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: file)

        // Restore
        let restore = MGSwipeButton(
            title: NSLocalizedString("Restore", comment: "Button title"),
            icon: Asset.Images.listMenuRestore.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.recover(cell: cell)
            return true
        }

        // Delete
        let delete = MGSwipeButton(
            title: NSLocalizedString("Delete", comment: "Button title"),
            icon: Asset.Images.listMenuTrash.image,
            backgroundColor: ASCConstants.Colors.red
        )
        delete.callback = { [unowned self] cell -> Bool in
            guard view.isUserInteractionEnabled else { return true }

            self.deleteIfNeeded(cell: cell, menuButton: delete) { cell, allowDelete in
                guard let cell = cell as? MGSwipeTableCell else { return }

                cell.hideSwipe(animated: true)

                if allowDelete {
                    self.delete(cell: cell)
                }
            }
            return false
        }

        // Download
        let download = MGSwipeButton(
            title: NSLocalizedString("Download", comment: "Button title"),
            icon: Asset.Images.listMenuDownload.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.download(cell: cell)
            return true
        }

        // Rename
        let rename = MGSwipeButton(
            title: NSLocalizedString("Rename", comment: "Button title"),
            icon: Asset.Images.listMenuRename.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.rename(cell: cell)
            return true
        }

        // Copy
        let copy = MGSwipeButton(
            title: NSLocalizedString("Copy", comment: "Button title"),
            icon: Asset.Images.listMenuCopy.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.copy(cell: cell)
            return true
        }

        // More
        let more = MGSwipeButton(
            title: NSLocalizedString("More", comment: "Button title"),
            icon: Asset.Images.listMenuMore.image,
            backgroundColor: ASCConstants.Colors.lightGrey
        )
        more.callback = { [unowned self] swipedCell -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            self.more(cell: cell, menuButton: more)
            return false
        }

        cell.swipeBackgroundColor = ASCConstants.Colors.lighterGrey

        var items: [MGSwipeButton] = []

        if actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore) { items.append(restore) }
        if actions.contains(.rename) { items.append(rename) }
        if actions.contains(.copy) { items.append(copy) }
        if actions.contains(.download) { items.append(download) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return decorate(menu: items)
    }

    func buildFolderCellMenu(for cell: ASCFolderCell) -> [MGSwipeButton]? {
        guard
            let folder = cell.folder,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: folder)

        // Restore
        let restore = MGSwipeButton(
            title: NSLocalizedString("Restore", comment: "Button title"),
            icon: Asset.Images.listMenuRestore.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.recover(cell: cell)
            return true
        }

        // Delete
        let delete = MGSwipeButton(
            title: NSLocalizedString("Delete", comment: "Button title"),
            icon: Asset.Images.listMenuTrash.image,
            backgroundColor: ASCConstants.Colors.red
        )
        delete.callback = { [unowned self] cell -> Bool in
            guard view.isUserInteractionEnabled else { return true }

            self.deleteIfNeeded(cell: cell, menuButton: delete) { cell, allowDelete in
                guard let cell = cell as? MGSwipeTableCell else { return }

                cell.hideSwipe(animated: true)

                if allowDelete {
                    self.delete(cell: cell)
                }
            }
            return false
        }

        // Rename
        let rename = MGSwipeButton(
            title: NSLocalizedString("Rename", comment: "Button title"),
            icon: Asset.Images.listMenuRename.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.rename(cell: cell)
            return true
        }

        // Copy
        let copy = MGSwipeButton(
            title: NSLocalizedString("Copy", comment: "Button title"),
            icon: Asset.Images.listMenuCopy.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.copy(cell: cell)
            return true
        }

        // Archive
        let archive = MGSwipeButton(
            title: NSLocalizedString("Archive", comment: "Button title"),
            icon: Asset.Images.categoryArchived.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            self.archive(cell: cell)
            return true
        }

        // More
        let more = MGSwipeButton(
            title: NSLocalizedString("More", comment: "Button title"),
            icon: Asset.Images.listMenuMore.image,
            backgroundColor: ASCConstants.Colors.lightGrey
        )
        more.callback = { [unowned self] swipedCell -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            self.more(cell: cell, menuButton: more)
            return false
        }

        cell.swipeBackgroundColor = ASCConstants.Colors.lighterGrey

        var items: [MGSwipeButton] = []

        if actions.contains(.unmount) || actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore) { items.append(restore) }
        if actions.contains(.rename) { items.append(rename) }
        if actions.contains(.copy) { items.append(copy) }
        if actions.contains(.archive) { items.append(archive) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return decorate(menu: items)
    }

    private func decorate(menu buttons: [MGSwipeButton]) -> [MGSwipeButton] {
        for button in buttons {
            button.buttonWidth = 75
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.horizontalCenterIconOverText()
        }

        return buttons
    }

    // MARK: - Action menu

    func buildActionMenu(for cell: UITableViewCell) -> UIAlertController? {
        if cell is ASCFileCell {
            return buildFileActionMenu(for: cell)
        } else if cell is ASCFolderCell {
            return buildFolderActionMenu(for: cell)
        }
        return nil
    }

    func buildFileActionMenu(for cell: UITableViewCell) -> UIAlertController? {
        guard
            let cell = cell as? ASCFileCell,
            let file = cell.file,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: file)

        let actionAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        if actions.contains(.open) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.open(file: file, viewMode: true)
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
                        cell.hideSwipe(animated: true)
                        self.open(file: file)
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
                        cell.hideSwipe(animated: true)
                        self.download(cell: cell)
                    }
                )
            )
        }

        if actions.contains(.rename) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
                    }
                )
            )
        }

        return actionAlertController
    }

    func buildFolderActionMenu(for cell: UITableViewCell) -> UIAlertController? {
        guard
            let cell = cell as? ASCFolderCell,
            let folder = cell.folder,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
                        self.archive(cell: cell)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
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
                        cell.hideSwipe(animated: true)
                    }
                )
            )
        }

        return actionAlertController
    }
}

// MARK: - MGSwipeTableCellDelegate

extension ASCDocumentsViewController: MGSwipeTableCellDelegate {
    func swipeTableCell(_ cell: MGSwipeTableCell,
                        canSwipe direction: MGSwipeDirection,
                        from point: CGPoint) -> Bool
    {
        return direction != .leftToRight
    }

    func swipeTableCell(_ cell: MGSwipeTableCell,
                        swipeButtonsFor direction: MGSwipeDirection,
                        swipeSettings: MGSwipeSettings,
                        expansionSettings: MGSwipeExpansionSettings) -> [UIView]?
    {
        swipeSettings.transition = .border

        if direction == .rightToLeft {
            if let fileCell = cell as? ASCFileCell {
                return buildFileCellMenu(for: fileCell)
            } else if let folderCell = cell as? ASCFolderCell {
                return buildFolderCellMenu(for: folderCell)
            }
        }

        return nil
    }
}
