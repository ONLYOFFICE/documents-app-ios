//
//  ASCSharingSettingsVerifyRightHoldersRouter.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingSettingsVerifyRightHoldersRoutingLogic {
    func routeToAccessViewController(viewModel: ASCSharingSettingsAccessViewModel, segue: UIStoryboardSegue?)
    func routeToParentWithDoneCopmletion(segue: UIStoryboardSegue?)
}

protocol ASCSharingSettingsVerifyRightHoldersDataPassing
{
    var dataStore: ASCSharingSettingsVerifyRightHoldersDataStore? { get }
}

class ASCSharingSettingsVerifyRightHoldersRouter: NSObject, ASCSharingSettingsVerifyRightHoldersRoutingLogic, ASCSharingSettingsVerifyRightHoldersDataPassing {

    weak var viewController: ASCSharingSettingsVerifyRightHoldersViewController?
    var dataStore: ASCSharingSettingsVerifyRightHoldersDataStore?

    var accessViewController: ASCSharingSettingsAccessViewController?
    
    // MARK: Routing
    func routeToAccessViewController(viewModel: ASCSharingSettingsAccessViewModel, segue: UIStoryboardSegue?) {
        let isDestinationAlreadyInit = accessViewController != nil
        
        if !isDestinationAlreadyInit {
            accessViewController = ASCSharingSettingsAccessViewController()
        }
        guard
            let destinationViewController = accessViewController,
            let viewController = viewController,
            let destinationDataStore = accessViewController
        else { return }
        
        passDataToAddRightHoldersViewController(viewModel: viewModel, destination: destinationDataStore)
        navigateToAddRightHoldersViewController(source: viewController, destination: destinationViewController)
    }
    
    private func navigateToAddRightHoldersViewController(source: ASCSharingSettingsVerifyRightHoldersViewController, destination: ASCSharingSettingsAccessViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    private func passDataToAddRightHoldersViewController(viewModel: ASCSharingSettingsAccessViewModel, destination: ASCSharingSettingsAccessViewController) {
        destination.viewModel = viewModel
    }
    
    func routeToParentWithDoneCopmletion(segue: UIStoryboardSegue?) {
        viewController?.navigationController?.dismiss(animated: true, completion: {
            self.dataStore?.doneComplerion()
            self.dataStore?.clearData()
        })
    }
}
