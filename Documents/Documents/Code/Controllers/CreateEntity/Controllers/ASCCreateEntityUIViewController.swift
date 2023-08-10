//
//  ASCCreateEntityUIViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class ASCCreateEntityUIViewController: UIHostingController<ASCCreateEntityUI> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder,
            rootView: ASCCreateEntityUI(allowClouds: .constant(true), onAction: .constant { type in })
        )
    }

    init(allowClouds: Bool, onAction: @escaping (CreateEntityUIType) -> Void) {
        super.init(
            rootView: ASCCreateEntityUI(
                allowClouds: .constant(allowClouds),
                onAction: .constant(onAction)
            )
        )
        view?.backgroundColor = .systemGroupedBackground
    }
//
//    func setAllowClouds(_ allow: Bool) {
//        rootView.allowClouds = allow
//    }
}
