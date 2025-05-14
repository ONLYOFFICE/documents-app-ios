//
//  VDRFillingStatusUIHostingController.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 14.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class VDRFillingStatusUIHostingController: UIHostingController<VDRFillingStatusView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }

    init() {
        let viewModel = VDRFillingStatusViewModel()
        let view = VDRFillingStatusView(
            viewModel: viewModel
        )
        super.init(rootView: view)
    }
}
