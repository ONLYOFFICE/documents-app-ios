//
//  ASCEditorManagerExtension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31.01.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor
import Foundation

extension ASCEditorManager: ASCEditorManagerProtocol {
    // MARK: - Properties

    var allowForm: Bool {
        true
    }

    // MARK: - Methods

    func localEditor(config: [String: Any]) -> [String: Any] {
        return config
    }

    func cloudEditor(config: [String: Any]) -> [String: Any] {
        return config
    }

    func localEditor(config: EditorConfiguration) -> EditorConfiguration {
        return config
    }
}
