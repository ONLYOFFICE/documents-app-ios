//
//  ASCDocSpaceLinkViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class ASCDocSpaceLinkViewController: UIHostingController<ASCDocSpaceLinkView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder,
            rootView: ASCDocSpaceLinkView(viewModel: .init(screenState: .additionalLinkState))
        )
    }

    init(onAction: @escaping (ASCDocSpaceLinkView) -> Void) {
        super.init(
            rootView: ASCDocSpaceLinkView(viewModel: .init(screenState: .additionalLinkState))
        )
    }
}
