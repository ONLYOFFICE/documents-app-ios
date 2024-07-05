//
//  ASCDocumentsCellContextMenu.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCDocumentsCellContextMenu {
    typealias InterfaceInteractable = () -> Bool

    func buildCellMenu(cell: UICollectionView, interfaceInteractable: @escaping InterfaceInteractable) -> UIMenu?
}
