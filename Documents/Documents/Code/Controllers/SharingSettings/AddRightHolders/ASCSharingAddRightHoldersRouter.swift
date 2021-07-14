//
//  ASCSharingAddRightHoldersRouter.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersRoutingLogic {
    func routeToVerifyRightHoldersViewController(segue: UIStoryboardSegue?)
}

protocol ASCSharingAddRightHoldersDataPassing
{
    var dataStore: ASCSharingAddRightHoldersDataStore? { get }
}


class ASCSharingAddRightHoldersRouter: NSObject, ASCSharingAddRightHoldersRoutingLogic, ASCSharingAddRightHoldersDataPassing {
    
    var dataStore: ASCSharingAddRightHoldersDataStore?
    
    weak var viewController: ASCSharingAddRightHoldersViewController?
    var verifyRightHoldersViewController: ASCSharingSettingsVerifyRightHoldersViewController?
    
    // MARK: Routing
    func routeToVerifyRightHoldersViewController(segue: UIStoryboardSegue?) {
        let isDestinationAlreadyInit = verifyRightHoldersViewController != nil
        
        if isDestinationAlreadyInit {
            verifyRightHoldersViewController?.reset()
        } else {
            verifyRightHoldersViewController = ASCSharingSettingsVerifyRightHoldersViewController()
        }
        guard
            let destinationViewController = verifyRightHoldersViewController,
            let viewController = viewController,
            let sourceDataStore = dataStore,
            var destinationDataStore = destinationViewController.router?.dataStore
        else { return }
        
        passDataToAddRightHoldersViewController(source: sourceDataStore, destination: &destinationDataStore)
        navigateToAddRightHoldersViewController(source: viewController, destination: destinationViewController)
        if isDestinationAlreadyInit {
            destinationViewController.load()
        }
    }
    
    private func navigateToAddRightHoldersViewController(source: ASCSharingAddRightHoldersViewController, destination: ASCSharingSettingsVerifyRightHoldersViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    private func passDataToAddRightHoldersViewController(source: ASCSharingAddRightHoldersDataStore, destination: inout ASCSharingSettingsVerifyRightHoldersDataStore) {
        destination.sharedInfoItems = source.sharedInfoItems
        destination.itemsForSharingAdd = source.itemsForSharingAdd
        destination.itemsForSharingRemove = source.itemsForSharingRemove
        destination.entity = source.entity
    }
}
