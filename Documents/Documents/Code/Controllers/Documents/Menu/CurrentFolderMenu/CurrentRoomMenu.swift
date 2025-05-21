//
//  CurrentRoomMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentRoomMenu: CurrentFolderMenuProtocol {
    private lazy var sortTypes: [ASCDocumentSortType] = [.az, .type, .tag, .author, .dateandtime]

    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        guard let provider = viewController.provider else { return UIMenu() }
        let actions = provider.actions(for: folder)

        var selectGroup: [UIMenuElement] = []

        // Select
        if actions.contains(.select) {
            selectGroup.append(
                UIAction(title: NSLocalizedString("Select", comment: ""), image: UIImage(systemName: "checkmark.circle"), handler: { _ in
                    viewController.onSelectAction()
                })
            )
        }

        // View

        var viewGroup: [UIMenuElement] = []

        if !folder.parentsFoldersOrCurrentContains(keyPath: \.indexing, value: true) {
            viewGroup.append(
                UIAction(
                    title: NSLocalizedString("Icons", comment: "Button title"),
                    image: UIImage(systemName: "square.grid.2x2"),
                    state: viewController.itemsViewType == .grid ? .on : .off
                ) { [weak viewController] action in
                    viewController?.itemsViewType = .grid
                }
            )
        }

        viewGroup.append(
            UIAction(
                title: NSLocalizedString("List", comment: "Button title"),
                image: UIImage(systemName: "list.bullet"),
                state: viewController.itemsViewType == .list ? .on : .off
            ) { [weak viewController] action in
                viewController?.itemsViewType = .list
            }
        )

        var entityActionsGroup: [UIMenuElement] = []

        // Edit room
        if actions.contains(.edit) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Edit room", comment: "Button title"),
                    image: UIImage(systemName: "gear")
                ) { [weak viewController] action in
                    viewController?.editRoom(folder: folder)
                }
            )
        }

        // Invite users
        if actions.contains(.addUsers) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Invite users", comment: "Button title"),
                    image: UIImage(systemName: "person.badge.plus")
                ) { [weak viewController] action in
                    viewController?.navigator.navigate(to: .addUsers(entity: folder))
                }
            )
        }

        // Copy general link
        if actions.contains(.link) {
            entityActionsGroup.append(
                UIAction(
                    title: folder.roomType == .colobaration
                        ? NSLocalizedString("Copy link", comment: "Button title")
                        : NSLocalizedString("Copy general link", comment: "Button title"),
                    image: UIImage(systemName: "link")
                ) { [weak viewController] action in
                    viewController?.copyGeneralLinkToClipboard(room: folder)
                }
            )
        }

        // Info
        if actions.contains(.info) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Info", comment: "Button title"),
                    image: UIImage(systemName: "info.circle")
                ) { [weak viewController] action in
                    viewController?.navigator.navigate(to: .shareSettings(entity: folder))
                }
            )
        }

        // Export room index
        if actions.contains(.exportRoomIndex) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Export room index", comment: "Button title"),
                    image: UIImage(systemName: "arrow.down.document")
                ) { [weak viewController] action in
                    viewController?.exportRoomIndex()
                }
            )
        }

        if actions.contains(.disableNotifications) {
            entityActionsGroup.append(
                UIAction(
                    title: folder.mute
                        ? NSLocalizedString("Disable notifications", comment: "")
                        : NSLocalizedString("Enable notifications", comment: ""),
                    image: folder.mute
                        ? UIImage(systemName: "bell.slash")
                        : UIImage(systemName: "bell")
                ) { [weak viewController] _ in
                    viewController?.disableNotifications(room: folder)
                }
            )
        }
        
        if actions.contains(.saveAsTemplate) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Save as template", comment: ""),
                    image: UIImage(systemName: "note.text.badge.plus")
                ) { [weak viewController] _ in
                    viewController?.saveAsTemplate(room: folder)
                }
            )
        }

        var entityOperationsGroup: [UIMenuElement] = []

        // Download
        if actions.contains(.download) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.down")
                ) { [weak viewController] action in
                    viewController?.downloadFolder(cell: nil, folder: folder)
                }
            )
        }

        // Edit index
        if actions.contains(.editIndex) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Edit index", comment: "Button title"),
                    image: UIImage(systemName: "line.3.horizontal.decrease")
                ) { [weak viewController] action in
                    viewController?.isEditingIndexMode = true
                }
            )
        }

        // Change room owner
        if actions.contains(.changeRoomOwner) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Change room owner", comment: "Button title"),
                    image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                ) { [weak viewController] action in
                    viewController?.leaveRoom(cell: nil, folder: folder, changeOwner: true)
                }
            )
        }

        // Move to archive
        if actions.contains(.archive) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Move to archive", comment: "Button title"),
                    image: UIImage(systemName: "archivebox")
                ) { [weak viewController] action in
                    viewController?.archive(cell: nil, folder: folder)
                }
            )
        }

        if actions.contains(.leave) {
            // Leave the room
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Leave the room", comment: "Button title"),
                    image: UIImage(systemName: "arrow.right.square")
                ) { [weak viewController] action in
                    viewController?.leaveRoom(cell: nil, folder: folder)
                }
            )
        }

        // Sort
        var sortGroup: [UIMenuElement] = []

        if !folder.isRoot {
            sortTypes = [.az, .size, .dateandtime]
        }

        let (sortType, sortAscending) = sortDetails(sortInfo: sortInfo(forRootFolderType: folder))
        let sortStates: [ASCDocumentSortStateType] = sortTypes.map { ($0, $0 == sortType) }

        if !folder.isEmpty || folder.roomType == nil {
            for sort in sortStates {
                sortGroup.append(
                    Self.buildUIAction(
                        sortState: sort,
                        sortType: sortType,
                        sortAscending: sortAscending,
                        folder: folder
                    )
                )
            }
        }

        let selectMenu = UIMenu(title: "", options: .displayInline, children: selectGroup)
        let viewMenu = UIMenu(title: "", options: .displayInline, children: viewGroup)
        let entityActionsMenu = UIMenu(title: "", options: .displayInline, children: entityActionsGroup)
        let entityOperationsMenu = UIMenu(title: "", options: .displayInline, children: entityOperationsGroup)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortGroup)

        let menus: [UIMenuElement] = [
            selectMenu,
            viewMenu,
            entityActionsMenu,
            entityOperationsMenu,
            sortMenu,
        ]

        return UIMenu(title: "", options: [.displayInline], children: menus)
    }

    func actionSheet(for folder: ASCFolder, sender: UIView?, in viewController: ASCDocumentsViewController) -> UIAlertController {
        let moreController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        moreController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                style: .default,
                handler: { [unowned viewController] action in
                    viewController.setEditMode(!viewController.collectionView.isEditing)
                }
            )
        )

        moreController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Sort", comment: "Button title"),
                style: .default,
                handler: { [unowned viewController] action in
                    if let sender {
                        viewController.onSortAction(sender)
                    }
                }
            )
        )

        moreController.addAction(
            UIAlertAction(
                title: ASCLocalization.Common.cancel,
                style: .cancel,
                handler: nil
            )
        )

        return moreController
    }
}
