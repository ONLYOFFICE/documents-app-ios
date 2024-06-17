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
    func localEditor(config: DocumentEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> DocumentEditor.EditorConfiguration
    func cloudEditor(config: DocumentEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> DocumentEditor.EditorConfiguration
}

protocol ASCSpreadsheetEditorConfigurationProtocol: ASCEditorConfigurationProtocol {
    func localEditor(config: SpreadsheetEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> SpreadsheetEditor.EditorConfiguration
    func cloudEditor(config: SpreadsheetEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> SpreadsheetEditor.EditorConfiguration
}

protocol ASCPresentationEditorConfigurationProtocol: ASCEditorConfigurationProtocol {
    func localEditor(config: PresentationEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> PresentationEditor.EditorConfiguration
    func cloudEditor(config: PresentationEditor.EditorConfiguration, file: ASCFile?, provider: ASCFileProviderProtocol?) -> PresentationEditor.EditorConfiguration
}
