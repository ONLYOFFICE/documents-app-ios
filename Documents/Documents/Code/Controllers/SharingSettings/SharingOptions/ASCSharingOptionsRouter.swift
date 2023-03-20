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
    func routeToInviteRightHoldersViewController(segue: UIStoryboardSegue?, sourceViewController: UIViewController?)
}

protocol ASCSharingOptionsDataPassing {
    var dataStore: ASCSharingOptionsDataStore? { get }
}

class ASCSharingOptionsRouter: NSObject, ASCSharingOptionsRoutingLogic, ASCSharingOptionsDataPassing {
    var dataStore: ASCSharingOptionsDataStore?

    var addRightHoldersViewController: ASCSharingAddRightHoldersViewController?
    var inviteRightHolderViewController: ASCSharingInviteRightHoldersViewController?

    weak var sourceViewController: UIViewController?

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
        passDataToAddRightHoldersViewController(source: sourceDataStore, destination: &destinationDataStore) {}
        navigate(source: viewController, destination: destinationViewController)

        if isDestinationAlreadyInit {
            destinationViewController.start()
        }
    }

    func routeToInviteRightHoldersViewController(segue: UIStoryboardSegue?, sourceViewController: UIViewController?) {
        var isDestinationAlreadyInit = false
        self.sourceViewController = sourceViewController
        if inviteRightHolderViewController != nil {
            isDestinationAlreadyInit = true
            inviteRightHolderViewController?.reset()
        } else {
            inviteRightHolderViewController = ASCSharingInviteRightHoldersViewController()
        }
        guard
            let destinationViewController = inviteRightHolderViewController,
            let viewController = viewController,
            let sourceDataStore = dataStore,
            var destinationDataStore = destinationViewController.router?.dataStore
        else { return }

        destinationViewController.accessProvider = viewController.accessProviderFactory.get(entity: viewController.entity ?? ASCEntity(), isAccessExternal: false)
        passDataToAddRightHoldersViewController(source: sourceDataStore, destination: &destinationDataStore) { [weak sourceViewController] in
            guard let sourceViewController = sourceViewController else { return }
            let message = NSLocalizedString("Link with the invitation has been sent to the mail", comment: "")
            let controller = UIAlertController(title: "", message: message, preferredStyle: .alert).okable()
            sourceViewController.present(controller, animated: true)
        }
        navigate(source: viewController, destination: destinationViewController)

        if isDestinationAlreadyInit {
            destinationViewController.start()
        }
    }

    private func navigate(source: UIViewController, destination: UIViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }

    private func passDataToAddRightHoldersViewController(source: ASCSharingOptionsDataStore, destination: inout ASCSharingAddRightHoldersBaseDataStore, doneCompletion: @escaping () -> Void) {
        destination.sharedInfoItems = source.sharedInfoItems
        destination.currentUser = source.currentUser
        destination.entity = source.entity
        destination.doneCompletion = doneCompletion
        destination.entityOwner = source.entityOwner
    }
}
