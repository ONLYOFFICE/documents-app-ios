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
            rootView: ASCCreateEntityUI(allowClouds: .constant(true), 
                                        allowForms: .constant(true), 
                                        onAction: .constant { type in })
        )
    }

    init(allowClouds: Bool, allowForms: Bool, onAction: @escaping (CreateEntityUIType) -> Void) {
        super.init(
            rootView: ASCCreateEntityUI(
                allowClouds: .constant(allowClouds), 
                allowForms: .constant(allowForms),
                onAction: .constant(onAction)
            )
        )
        view?.backgroundColor = Asset.Colors.createPanel.color
    }
}
