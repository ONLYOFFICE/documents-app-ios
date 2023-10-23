//
//  ASCEditorExternalSettingsProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

protocol ASCEditorExternalSettingsProtocol {
    var editorExternalSettings: [AnyHashable: Any] { get }
}

protocol ASCDocumentEditorExternalSettingsProtocol: ASCEditorExternalSettingsProtocol {}
protocol ASCSpreadsheetEditorExternalSettingsProtocol: ASCEditorExternalSettingsProtocol {}
protocol ASCPresentationEditorExternalSettingsProtocol: ASCEditorExternalSettingsProtocol {}
