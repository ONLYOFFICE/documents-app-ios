//
//  ASCDocumentsFolderCellContextMenu.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import MGSwipeTableCell

final class ASCDocumentsFolderCellContextMenu: ASCDocumentsCellContextMenu {
    var provider: ASCFileProviderProtocol?
    var folder: ASCFolder?

    init(provider: ASCFileProviderProtocol? = nil) {
        self.provider = provider
    }

    @available(iOS 13.0, *)
    func buildCellMenu(cell: MGSwipeTableCell, interfaceInteractable: @escaping InterfaceInteractable) -> UIMenu? {
        guard
            let cell = cell as? ASCFolderCell,
            let folder = cell.folder,
            let provider = provider,
            interfaceInteractable()
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
            //   self.recover(cell: cell)
            true
        }

        // Delete
        let delete = MGSwipeButton(
            title: NSLocalizedString("Delete", comment: "Button title"),
            icon: Asset.Images.listMenuTrash.image,
            backgroundColor: ASCConstants.Colors.red
        )
        delete.callback = { [unowned self] cell -> Bool in
            guard interfaceInteractable() else { return true }

//            self.deleteIfNeeded(cell: cell, menuButton: delete) { cell, allowDelete in
//                guard let cell = cell as? MGSwipeTableCell else { return }
//
//                cell.hideSwipe(animated: true)
//
//                if allowDelete {
//                    self.delete(cell: cell)
//                }
//            }
            return false
        }

        // Rename
        let rename = MGSwipeButton(
            title: NSLocalizedString("Rename", comment: "Button title"),
            icon: Asset.Images.listMenuRename.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            // self.rename(cell: cell)
            true
        }

        // Copy
        let copy = MGSwipeButton(
            title: NSLocalizedString("Copy", comment: "Button title"),
            icon: Asset.Images.listMenuCopy.image,
            backgroundColor: ASCConstants.Colors.grey
        ) { [unowned self] cell -> Bool in
            // self.copy(cell: cell)
            true
        }

        // More
        let more = MGSwipeButton(
            title: NSLocalizedString("More", comment: "Button title"),
            icon: Asset.Images.listMenuMore.image,
            backgroundColor: ASCConstants.Colors.lightGrey
        )
        more.callback = { [unowned self] swipedCell -> Bool in
            guard interfaceInteractable() else { return true }
            // self.more(cell: cell, menuButton: more)
            return false
        }

        cell.swipeBackgroundColor = ASCConstants.Colors.lighterGrey

        var items: [MGSwipeButton] = []

        if actions.contains(.unmount) || actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore) { items.append(restore) }
        if actions.contains(.rename) { items.append(rename) }
        if actions.contains(.copy) { items.append(copy) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        // return decorate(menu: items)
        return nil
    }
}
