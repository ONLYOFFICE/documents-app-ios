//
//  ASCEditorConfigurationProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor
import PresentationEditor
import SpreadsheetEditor

protocol ASCEditorConfigurationProtocol {
    var editorExternalSettings: [AnyHashable: Any] { get }
}

protocol ASCDocumentEditorConfigurationProtocol: ASCEditorConfigurationProtocol {
    func localEditor(config: DocumentEditor.EditorConfiguration) -> DocumentEditor.EditorConfiguration
    func cloudEditor(config: DocumentEditor.EditorConfiguration) -> DocumentEditor.EditorConfiguration
}

protocol ASCSpreadsheetEditorConfigurationProtocol: ASCEditorConfigurationProtocol {
    func localEditor(config: SpreadsheetEditor.EditorConfiguration) -> SpreadsheetEditor.EditorConfiguration
    func cloudEditor(config: SpreadsheetEditor.EditorConfiguration) -> SpreadsheetEditor.EditorConfiguration
}

protocol ASCPresentationEditorConfigurationProtocol: ASCEditorConfigurationProtocol {
    func localEditor(config: PresentationEditor.EditorConfiguration) -> PresentationEditor.EditorConfiguration
    func cloudEditor(config: PresentationEditor.EditorConfiguration) -> PresentationEditor.EditorConfiguration
}
