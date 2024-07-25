//
//  SharedSettingsRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 31.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class SharedSettingsRootViewController: UIHostingController<SharedSettingsView> {
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    init(file: ASCFile) {
        super.init(
            rootView: SharedSettingsView(
                viewModel: .init(file: file)
            )
        )
    }
}
