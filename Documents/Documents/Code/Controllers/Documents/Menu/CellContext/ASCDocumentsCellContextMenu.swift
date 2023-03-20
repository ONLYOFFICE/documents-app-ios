//
//  ASCDocumentsCellContextMenu.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MGSwipeTableCell

protocol ASCDocumentsCellContextMenu {
    typealias InterfaceInteractable = () -> Bool
    @available(iOS 13.0, *)
    func buildCellMenu(cell: MGSwipeTableCell, interfaceInteractable: @escaping InterfaceInteractable) -> UIMenu?
}
