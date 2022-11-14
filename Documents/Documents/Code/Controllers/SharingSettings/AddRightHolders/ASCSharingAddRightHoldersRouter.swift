//
//  ASCSharingAddRightHoldersRouter.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersRoutingLogic {
    func routeToVerifyRightHoldersViewController(segue: UIStoryboardSegue?, clearSharedInfoItems: Bool)
}

extension ASCSharingAddRightHoldersRoutingLogic {
    func routeToVerifyRightHoldersViewController(segue: UIStoryboardSegue?, clearSharedInfoItems: Bool = false) {
        routeToVerifyRightHoldersViewController(segue: segue, clearSharedInfoItems: clearSharedInfoItems)
    }
}

protocol ASCSharingAddRightHoldersDataPassing {
    var dataStore: ASCSharingAddRightHoldersBaseDataStore? { get }
}

class ASCSharingAddRightHoldersRouter: NSObject, ASCSharingAddRightHoldersRoutingLogic, ASCSharingAddRightHoldersDataPassing {
    var dataStore: ASCSharingAddRightHoldersBaseDataStore?

    weak var viewController: UIViewController?
    var verifyRightHoldersViewController: ASCSharingSettingsVerifyRightHoldersViewController?

    // MARK: Routing

    func routeToVerifyRightHoldersViewController(segue: UIStoryboardSegue?, clearSharedInfoItems: Bool = false) {
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

        passDataToAddRightHoldersViewController(source: sourceDataStore, destination: &destinationDataStore, clearSharedInfoItems: clearSharedInfoItems)
        navigateToVerifyRightHoldersViewController(source: viewController, destination: destinationViewController)
        if isDestinationAlreadyInit {
            destinationViewController.load()
        }
    }

    private func navigateToVerifyRightHoldersViewController(source: UIViewController, destination: ASCSharingSettingsVerifyRightHoldersViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }

    private func passDataToAddRightHoldersViewController(source: ASCSharingAddRightHoldersBaseDataStore, destination: inout ASCSharingSettingsVerifyRightHoldersDataStore, clearSharedInfoItems: Bool) {
        destination.clearData()
        if clearSharedInfoItems {
            destination.sharedInfoItems = []
        } else {
            destination.sharedInfoItems = source.sharedInfoItems
        }
        destination.itemsForSharingAdd = source.itemsForSharingAdd
        destination.itemsForSharingRemove = source.itemsForSharingRemove
        destination.entity = source.entity
        destination.doneComplerion = source.doneComplerion
    }
}
