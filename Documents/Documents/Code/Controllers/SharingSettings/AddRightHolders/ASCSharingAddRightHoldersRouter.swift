//
//  ASCSharingAddRightHoldersRouter.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersRoutingLogic {
    
}

protocol ASCSharingAddRightHoldersDataPassing
{
    var dataStore: ASCSharingAddRightHoldersDataStore? { get }
}


class ASCSharingAddRightHoldersRouter: NSObject, ASCSharingAddRightHoldersRoutingLogic, ASCSharingAddRightHoldersDataPassing {
    
    var dataStore: ASCSharingAddRightHoldersDataStore?
    
    weak var viewController: ASCSharingAddRightHoldersViewController?
    
    // MARK: Routing
    
}
