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
    case leaveRoom(entity: ASCEntity, handler: ASCEntityHandler?)
    case roomSharingLink(folder: ASCFolder)

    // MARK: - Login

    case onlyofficeConnectPortal(portal: String?)
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
    case themeOptions
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
            var shareRoomNavigationVC: ASCBaseNavigationController?
            if entity.isRoom {
                if let room = entity as? ASCFolder {
                    let shareRoomViewController = RoomSharingRootViewController(room: room)
                    shareRoomNavigationVC = ASCBaseNavigationController(rootASCViewController: shareRoomViewController)
                }
            } else if let sharedViewController = viewController as? ASCSharingOptionsViewController {
                shareRoomNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedViewController)
                sharedViewController.setup(entity: entity)
                sharedViewController.requestToLoadRightHolders()
            }

            if let shareRoomNavigationVC {
                shareRoomNavigationVC.modalPresentationStyle = .formSheet
                shareRoomNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
                navigationController?.present(shareRoomNavigationVC, animated: true, completion: nil)
            }

        case .addUsers:
            let nc = ASCBaseNavigationController(rootASCViewController: viewController)
            nc.modalPresentationStyle = .formSheet
            nc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
            navigationController?.present(nc, animated: true, completion: nil)
        case let .leaveRoom(entity, handler):
            if let leaveRoomViewController = viewController as? ASCSharingChooseNewOwnerRightHoldersViewController {
                let leaveRoomNavigationVC = ASCBaseNavigationController(rootASCViewController: leaveRoomViewController)

                leaveRoomNavigationVC.modalPresentationStyle = .formSheet
                leaveRoomNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

                navigationController?.present(leaveRoomNavigationVC, animated: true, completion: nil)

                leaveRoomViewController.dataStore?.entity = entity
                leaveRoomViewController.dataStore?.currentUser = ASCFileManager.onlyofficeProvider?.user
                leaveRoomViewController.handler = handler
            }

        case let .onlyofficeConnectPortal(portal):
            if let connectPortalViewController = viewController as? ASCConnectPortalViewController {
                navigationController?.viewControllers = [connectPortalViewController]
                if let portal {
                    connectPortalViewController.forceConnect(to: portal)
                }
            }

        case .roomSharingLink:
            if let shareRoomViewController = viewController as? RoomSharingRootViewController {
                let shareRoomNavigationVC = ASCBaseNavigationController(rootASCViewController: shareRoomViewController)

                shareRoomNavigationVC.modalPresentationStyle = .formSheet
                shareRoomNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

                navigationController?.present(shareRoomNavigationVC, animated: true, completion: nil)
            }

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
        case let .addUsers(folder):
            if let folder = folder as? ASCFolder {
                let vc = InviteUsersViewController(folder: folder)
                return vc
            }
            return UIViewController()
        case .leaveRoom:
            let vc = ASCSharingChooseNewOwnerRightHoldersViewController()
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
        case .themeOptions:
            return ASCAppThemeViewController()
        case let .roomSharingLink(folder):
            return RoomSharingRootViewController(room: folder)
        }
    }
}
