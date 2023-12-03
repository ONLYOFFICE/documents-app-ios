//
//  CreateGeneralLinkViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class CreateGeneralLinkViewController: UIHostingController<CreateGeneralLinkView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder,
            rootView: CreateGeneralLinkView()
        )
    }

    init(onAction: @escaping (CreateGeneralLinkView) -> Void) {
        super.init(
            rootView: CreateGeneralLinkView()
        )
    }
}
