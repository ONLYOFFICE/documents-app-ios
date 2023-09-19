//
//  ASCLoadedDocumentViewControllerByProviderAndFolderFinder.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

class ASCLoadedDocumentViewControllerByProviderAndFolderFinder: ASCLoadedViewControllerFinderProtocol {
    func find(requestModel: ASCLoadedVCFinderModels.DocumentsVC.Request) -> ASCLoadedVCFinderModels.DocumentsVC.Response {
        let nilResult = ASCLoadedVCFinderModels.DocumentsVC.Response(viewController: nil)

        guard !requestModel.folderId.isEmpty, !requestModel.providerId.isEmpty else {
            return nilResult
        }

        let allDocumentsNavigationControllers = getAllASCDocumentsNavigationControllers()

        guard let navigationControllerWithNeededProvider = getFirstASCDocumentsNavigationController(
            navigationControllers: allDocumentsNavigationControllers,
            withProviderId: requestModel.providerId
        )
        else {
            return nilResult
        }

        guard let documentsViewControllerWithNeededFolder = getFirstASCDocumentsViewController(
            navigationController: navigationControllerWithNeededProvider,
            withFolderId: requestModel.folderId
        )
        else {
            return nilResult
        }

        return ASCLoadedVCFinderModels.DocumentsVC.Response(viewController: documentsViewControllerWithNeededFolder)
    }

    func getAllASCDocumentsNavigationControllers() -> [ASCDocumentsNavigationController] {
        guard let root = getRootViewController() else {
            return []
        }

        var queue: [UIViewController] = []
        var values: [ASCDocumentsNavigationController] = []

        queue.append(root)

        while !queue.isEmpty {
            let vc = queue.removeFirst()
            if let nc = vc as? ASCDocumentsNavigationController {
                values.append(nc)
            } else {
                queue.append(contentsOf: vc.children)
            }
        }
        return values
    }

    func getFirstASCDocumentsNavigationController(navigationControllers: [ASCDocumentsNavigationController], withProviderId providerId: String) -> ASCDocumentsNavigationController? {
        guard !navigationControllers.isEmpty, !providerId.isEmpty else {
            return nil
        }

        return navigationControllers.first(where: {
            guard let documentsVC = $0.children.first as? ASCDocumentsViewController else {
                return false
            }
            return documentsVC.provider?.id == providerId
        })
    }

    func getFirstASCDocumentsViewController(navigationController: ASCDocumentsNavigationController, withFolderId folderId: String) -> ASCDocumentsViewController? {
        for child in navigationController.children {
            if let documentsVC = child as? ASCDocumentsViewController, documentsVC.folder?.id == folderId {
                return documentsVC
            }
        }
        return nil
    }
}
