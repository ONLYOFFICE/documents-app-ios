//
//  ASCNavigator.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum Destination {
    // MARK: - Documents

    case sort(types: [ASCDocumentSortStateType], ascending: Bool, complation: ASCSortViewController.ASCSortComplation?)
    case shareSettings(entity: ASCEntity)
    case addUsers(entity: ASCEntity)

    // MARK: - Login

    case onlyofficeConnectPortal
    case onlyofficeSignIn(portal: String?)
    case countryPhoneCodes

    // MARK: - Password recovery

    case recoveryPasswordByEmail
    case recoveryPasswordConfirmed(email: String)

    // MARK: - Settings

    case notificationSettings
    case about
    case passcodeLockSettings
    case developerOptions
}

final class ASCNavigator {
    // MARK: - Properties

    private weak var navigationController: UINavigationController?

    // MARK: - Initialize

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    // MARK: - Public

    @discardableResult
    func navigate(to destination: Destination) -> UIViewController? {
        let viewController = makeViewController(for: destination)

        switch destination {
        case let .sort(types, ascending, complation):
            if let sortViewController = viewController as? ASCSortViewController {
                sortViewController.types = types
                sortViewController.ascending = ascending
                sortViewController.onDone = complation
                let navigationVC = UINavigationController(rootASCViewController: sortViewController)
                navigationController?.present(navigationVC, animated: true, completion: nil)
            }
        case let .shareSettings(entity):
            if let sharedViewController = viewController as? ASCSharingOptionsViewController {
                let sharedNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedViewController)

                if UIDevice.pad {
                    sharedNavigationVC.modalPresentationStyle = .formSheet
                }

                navigationController?.present(sharedNavigationVC, animated: true, completion: nil)
                sharedViewController.setup(entity: entity)
                sharedViewController.requestToLoadRightHolders()
            }
        case let .addUsers(entity):
            if let addUsersViewController = viewController as? ASCSharingInviteRightHoldersViewController {
                let addUsersNavigationVC = ASCBaseNavigationController(rootASCViewController: addUsersViewController)
                if UIDevice.pad {
                    addUsersNavigationVC.modalPresentationStyle = .formSheet
                }
                navigationController?.present(addUsersNavigationVC, animated: true, completion: nil)
                addUsersViewController.dataStore?.entity = entity
                addUsersViewController.dataStore?.currentUser = ASCFileManager.onlyofficeProvider?.user
                addUsersViewController.accessProvider = ASCSharingSettingsAccessProviderFactory().get(entity: entity, isAccessExternal: false)
            }
        case .onlyofficeConnectPortal:
            navigationController?.viewControllers = [viewController]
        default:
            navigationController?.pushViewController(viewController, animated: true)
        }

        return viewController
    }

    // MARK: - Private

    private func makeViewController(for destination: Destination) -> UIViewController {
        switch destination {
        case .sort:
            return ASCSortViewController.instance()
        case .shareSettings:
            return ASCSharingOptionsViewController(sourceViewController: navigationController?.viewControllers.last)
        case .addUsers:
            let vc = ASCSharingInviteRightHoldersViewController()
            vc.sourceViewController = navigationController?.viewControllers.last
            return vc
        case .onlyofficeConnectPortal:
            return ASCConnectPortalViewController.instance()
        case let .onlyofficeSignIn(portal):
            let signinViewController = ASCSignInViewController.instance()
            signinViewController.portal = portal
            return signinViewController
        case .countryPhoneCodes:
            return ASCCountryCodeViewController.instance()
        case let .recoveryPasswordConfirmed(email):
            let controller = ASCEmailSentViewController.instance()
            controller.email = email
            return controller
        case .recoveryPasswordByEmail:
            return ASCPasswordRecoveryViewController.instance()
        case .notificationSettings:
            return ASCNotificationSettingsViewController()
        case .about:
            return ASCAboutViewController.instance()
        case .passcodeLockSettings:
            return ASCPasscodeLockViewController.instance()
        case .developerOptions:
            return ASCDevelopOptionsViewController()
        }
    }
}
