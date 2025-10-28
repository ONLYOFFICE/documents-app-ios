//
//  VDRFillingStatusUIHostingController.swift
//  Documents
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

    init(
        file: ASCFile,
        onStoppedSuccess: @escaping () -> Void,
        onFillTapped: @escaping () -> Void
    ) {
        let service = VDRFillingStatusService(
            sharedService: NetworkManagerSharedSettings()
        )
        let viewModel = VDRFillingStatusViewModel(
            service: service,
            file: file,
            onStoppedSuccess: onStoppedSuccess
        )
        let view = VDRFillingStatusView(
            viewModel: viewModel,
            onFillTapped: onFillTapped,
            onGoToRoomTapped: {}
        )
        super.init(rootView: view)
    }
}
