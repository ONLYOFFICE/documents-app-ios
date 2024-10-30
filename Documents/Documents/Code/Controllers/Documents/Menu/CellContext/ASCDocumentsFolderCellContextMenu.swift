//
//  ASCDocumentsFolderCellContextMenu.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD

final class ASCDocumentsFolderCellContextMenu: ASCDocumentsCellContextMenu, FileProviderHolder, FolderHolder {
    typealias DeleteIfNeededHandler = (UICollectionView, UIView, _ complation: @escaping (UICollectionView, Bool) -> Void) -> Void

    var provider: ASCFileProviderProtocol?
    var folder: ASCFolder?
    let removerActionController: ASCEntityRemoverActionController
    let deleteIfNeededhandler: DeleteIfNeededHandler

    init(provider: ASCFileProviderProtocol?,
         folder: ASCFolder?,
         removerActionController: ASCEntityRemoverActionController,
         deleteIfNeededhandler: @escaping DeleteIfNeededHandler)
    {
        self.provider = provider
        self.folder = folder
        self.removerActionController = removerActionController
        self.deleteIfNeededhandler = deleteIfNeededhandler
    }

    func buildCellMenu(cell: UICollectionView, interfaceInteractable: @escaping InterfaceInteractable) -> UIMenu? {
        // TODO: - Restore context menu logic here
        return nil
    }
}
