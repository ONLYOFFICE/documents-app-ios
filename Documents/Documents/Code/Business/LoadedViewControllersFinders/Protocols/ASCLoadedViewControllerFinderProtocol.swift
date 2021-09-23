//
//  ASCLoadedViewControllerFinderProtocol.swift
//  Documents
//
//  Created by Павел Чернышев on 28.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

protocol ASCLoadedViewControllerFinderProtocol {
    func find(requestModel: ASCLoadedVCFinderModels.DocumentsVC.Request) -> ASCLoadedVCFinderModels.DocumentsVC.Response
}

extension ASCLoadedViewControllerFinderProtocol {
    func getRootViewController() -> UIViewController? {
        UIApplication.shared.windows.first?.rootViewController
    }
}
