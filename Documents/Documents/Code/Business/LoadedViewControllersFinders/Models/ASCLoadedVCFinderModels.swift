//
//  ASCLoadedViewControllerFinderModels.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCLoadedVCFinderModels {
    enum DocumentsVC {
        struct Request {
            var folderId: String
            var providerId: String
        }

        struct Response {
            var viewController: ASCDocumentsViewController?
        }
    }
}
