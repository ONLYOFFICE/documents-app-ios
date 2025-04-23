//
//  ASCVersionHistoryRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 22.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class ASCVersionHistoryRootViewController: UIHostingController<ASCVersionHistoryView> {
    
    init(
        file: ASCFile,
        networkService: ASCVersionHistoryNetworkServiceProtocol
    ) {
        super.init(
            rootView: ASCVersionHistoryView(
                viewModel: ASCVersionHistoryViewModel(file: file, networkService: networkService)
            )
        )
    }
    
    @available(*, unavailable)
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

