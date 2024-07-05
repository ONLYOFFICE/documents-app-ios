//
//  InviteRigthHoldersByEmailsRepresentable.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct InviteRigthHoldersByEmailsRepresentable: UIViewControllerRepresentable {
    var entity: ASCEntity

    init(entity: ASCEntity) {
        self.entity = entity
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let nc = ASCBaseNavigationController()
        let viewModel = makeViewModel(navigationController: nc)
        let inviteVC = InviteRigthHoldersByEmailsViewController(viewModel: viewModel)
        nc.viewControllers = [inviteVC]
        nc.modalPresentationStyle = .formSheet
        return nc
    }

    private func makeViewModel(navigationController: ASCBaseNavigationController) -> InviteRigthHoldersByEmailsViewModel {
        let apiWorker = ASCShareSettingsAPIWorkerFactory().get(by: ASCPortalTypeDefinderByCurrentConnection().definePortalType())
        return InviteRigthHoldersByEmailsViewModelImp(
            entity: entity,
            currentAccess: .read,
            apiWorker: apiWorker,
            accessProvider: ASCSharingSettingsAccessDefaultProvider()
        ) { [weak navigationController] emails, access in
            let verifyVC = ASCSharingSettingsVerifyRightHoldersViewController()
            let dataStore = verifyVC.router?.dataStore
            dataStore?.itemsForSharingAdd = emails.map {
                .init(access: access, email: $0)
            }
            dataStore?.entity = entity
            dataStore?.doneCompletion = { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            }
            verifyVC.load()
            navigationController?.pushViewController(verifyVC, animated: true)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
