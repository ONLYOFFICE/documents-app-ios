//
//  ASCEditorManagerProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31.01.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCEditorManagerProtocol {
    var documentEditorExternalSettings: [AnyHashable: Any] { get }
    var spreadsheetEditorExternalSettings: [AnyHashable: Any] { get }
    var presentationEditorExternalSettings: [AnyHashable: Any] { get }
    var allowForm: Bool { get }

    func localEditor(config: [String: Any]) -> [String: Any]
    func cloudEditor(config: [String: Any]) -> [String: Any]
}
