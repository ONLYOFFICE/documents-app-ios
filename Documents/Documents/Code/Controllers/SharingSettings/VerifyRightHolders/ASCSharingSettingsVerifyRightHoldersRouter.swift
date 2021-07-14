//
//  ASCSharingSettingsVerifyRightHoldersRouter.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingSettingsVerifyRightHoldersRoutingLogic {
    
}

protocol ASCSharingSettingsVerifyRightHoldersDataPassing
{
    var dataStore: ASCSharingSettingsVerifyRightHoldersDataStore? { get }
}

class ASCSharingSettingsVerifyRightHoldersRouter: NSObject, ASCSharingSettingsVerifyRightHoldersRoutingLogic, ASCSharingSettingsVerifyRightHoldersDataPassing {
    
    weak var viewController: ASCSharingSettingsVerifyRightHoldersViewController?
    var dataStore: ASCSharingSettingsVerifyRightHoldersDataStore?
    // MARK: Routing
    
}
