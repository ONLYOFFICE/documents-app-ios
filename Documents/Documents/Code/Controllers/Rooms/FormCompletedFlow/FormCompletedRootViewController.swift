//
//  FormCompletedRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class CreateFormCompletedRootViewController: UIHostingController<FormCompletedView> {
    // MARK: - Lifecycle Methods

    init(formModel: FormModel, onCheckReadyForm: @escaping () -> Void) {
        super.init(
            rootView: FormCompletedView(
                viewModel: FormCompletedViewModel(
                    formModel: formModel,
                    onCheckReadyForm: onCheckReadyForm
                )
            )
        )
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
