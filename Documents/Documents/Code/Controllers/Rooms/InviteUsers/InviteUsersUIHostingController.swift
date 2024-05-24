//
//  InviteUsersUIHostingController.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 20.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class InviteUsersViewController: UIHostingController<InviteUsersView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }

    init(folder: ASCFolder) {
        let viewModel = InviteUsersViewModel(
            room: folder
        )
        let view = InviteUsersView(
            viewModel: viewModel
        )
        super.init(rootView: view)

        viewModel.dismissAction = { [weak self] in
            self?.dismiss(animated: true)
            self?.navigationController?.dismiss(animated: true)
        }
    }
}
