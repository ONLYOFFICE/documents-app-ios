//
//  ASCEditorManagerProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31.01.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor
import Foundation

protocol ASCEditorManagerProtocol {
    var allowForm: Bool { get }

    func localEditor(config: [String: Any]) -> [String: Any]
    func cloudEditor(config: [String: Any]) -> [String: Any]
    func localEditor(config: EditorConfiguration) -> EditorConfiguration
}
