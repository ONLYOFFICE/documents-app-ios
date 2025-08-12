//
//  VDRStartFillingUIHostingController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 29.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Under construction. Docspace 3.2 or later

class VDRStartFillingViewController: UIHostingController<VDRStartFillingView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }

    init(roles: [[String: Any]], onDismiss: @escaping (Result<Bool, any Error>) -> Void) {
        let viewModel = VDRStartFillingViewModel(roles: roles)
        let view = VDRStartFillingView(
            viewModel: viewModel,
            onDismiss: onDismiss
        )
        super.init(rootView: view)
    }
}
