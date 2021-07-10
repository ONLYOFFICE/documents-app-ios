//
//  ASCSharingOptionsRouter.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingOptionsRoutingLogic {
    func routeToAddRightHoldersViewController(segue: UIStoryboardSegue?)
}

protocol ASCSharingOptionsDataPassing
{
    var dataStore: ASCSharingOptionsDataStore? { get }
}

class ASCSharingOptionsRouter: NSObject, ASCSharingOptionsRoutingLogic, ASCSharingOptionsDataPassing {

    var dataStore: ASCSharingOptionsDataStore?
    
    var addRightHoldersViewController: ASCSharingAddRightHoldersViewController?
    
    
    weak var viewController: ASCSharingOptionsViewController?
    
    // MARK: Routing
    func routeToAddRightHoldersViewController(segue: UIStoryboardSegue?) {
        if addRightHoldersViewController == nil {
            addRightHoldersViewController = ASCSharingAddRightHoldersViewController()
        }
        guard
            let addRightHoldersViewController = addRightHoldersViewController,
            let viewController = viewController
        else { return }
        
        navigateToAddRightHoldersViewController(source: viewController, destination: addRightHoldersViewController)
        
    }
    
    private func navigateToAddRightHoldersViewController(source: ASCSharingOptionsViewController, destination: ASCSharingAddRightHoldersViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    private func paddDataToAddRightHoldersViewController(source: ASCSharingOptionsDataStore, destination: ASCSharingAddRightHoldersDataStore) {
        
    }
    
}
