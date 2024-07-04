//
//  CurrentLocalFolderMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentLocalFolderMenu: CurrentFolderMenuProtocol {
    private lazy var defaultsSortTypes: [ASCDocumentSortType] = [.dateandtime, .az, .type, .size]

    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        var selectActions: [UIMenuElement] = []
        var viewActions: [UIMenuElement] = []
        var sortActions: [UIMenuElement] = []

        selectActions.append(
            UIAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                image: UIImage(systemName: "checkmark.circle")
            ) { action in
                viewController.setEditMode(!viewController.collectionView.isEditing)
            }
        )

        viewActions.append(
            UIAction(
                title: NSLocalizedString("Icons", comment: "Button title"),
                image: UIImage(systemName: "square.grid.2x2"),
                state: ASCDocumentsViewController.itemsViewType == .grid ? .on : .off
            ) { action in
                ASCDocumentsViewController.itemsViewType = .grid
            }
        )

        viewActions.append(
            UIAction(
                title: NSLocalizedString("List", comment: "Button title"),
                image: UIImage(systemName: "list.bullet"),
                state: ASCDocumentsViewController.itemsViewType == .list ? .on : .off
            ) { action in
                ASCDocumentsViewController.itemsViewType = .list
            }
        )

        let (sortType, sortAscending) = sortDetails(sortInfo: sortInfo)
        let sortStates: [ASCDocumentSortStateType] = defaultsSortTypes.map { ($0, $0 == sortType) }

        for sort in sortStates {
            sortActions.append(
                Self.buildUIAction(
                    sortState: sort,
                    sortType: sortType,
                    sortAscending: sortAscending
                )
            )
        }

        let selectMenu = UIMenu(title: "", options: .displayInline, children: selectActions)
        let viewMenu = UIMenu(title: "", options: .displayInline, children: viewActions)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortActions)
        var menus: [UIMenuElement] = [sortMenu]

        menus.insert(viewMenu, at: 0)
        menus.insert(selectMenu, at: 0)

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
