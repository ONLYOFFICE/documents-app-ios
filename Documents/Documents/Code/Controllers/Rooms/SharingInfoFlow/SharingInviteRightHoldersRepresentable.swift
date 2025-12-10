//
//  SharingInviteRightHoldersRepresentable.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct SharingInviteRightHoldersRepresentable: UIViewControllerRepresentable {
    var entity: ASCEntity

    init(entity: ASCEntity) {
        self.entity = entity
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let addUsersController = ASCSharingInviteRightHoldersViewController()
        let addUsersNavigationVC = ASCBaseNavigationController(rootASCViewController: addUsersController)

        addUsersNavigationVC.modalPresentationStyle = .formSheet
        addUsersNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        addUsersController.dataStore?.entity = entity
        addUsersController.dataStore?.currentUser = ASCFileManager.onlyofficeProvider?.user
        addUsersController.accessProvider = ASCSharingSettingsAccessProviderFactory().get(entity: entity, isAccessExternal: false)

        return addUsersNavigationVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
