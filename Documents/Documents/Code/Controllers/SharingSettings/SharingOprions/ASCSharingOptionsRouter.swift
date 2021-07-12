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
        var isDestinationAlreadyInit = false
        if addRightHoldersViewController != nil {
            isDestinationAlreadyInit = true
            addRightHoldersViewController?.reset()
        } else {
            addRightHoldersViewController = ASCSharingAddRightHoldersViewController()
        }
        guard
            let destinationViewController = addRightHoldersViewController,
            let viewController = viewController,
            let sourceDataStore = dataStore,
            var destinationDataStore = destinationViewController.router?.dataStore
        else { return }
        
        destinationViewController.accessProvider = viewController.accessProviderFactory.get(entity: viewController.entity ?? ASCEntity(), isAccessExternal: false)
        passDataToAddRightHoldersViewController(source: sourceDataStore, destination: &destinationDataStore)
        navigateToAddRightHoldersViewController(source: viewController, destination: destinationViewController)
        if isDestinationAlreadyInit {
            destinationViewController.loadData()
        }
    }
    
    private func navigateToAddRightHoldersViewController(source: ASCSharingOptionsViewController, destination: ASCSharingAddRightHoldersViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    private func passDataToAddRightHoldersViewController(source: ASCSharingOptionsDataStore, destination: inout ASCSharingAddRightHoldersDataStore) {
        destination.sharedInfoItems = source.sharedInfoItems
        
    }
    
}
