//
//  VDRStartFillingUIHostingController.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 29.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

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
