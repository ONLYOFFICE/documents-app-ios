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

    init() {
        let viewModel = VDRStartFillingViewModel()
        let view = VDRStartFillingView(
            viewModel: viewModel
        )
        super.init(rootView: view)
    }
}
