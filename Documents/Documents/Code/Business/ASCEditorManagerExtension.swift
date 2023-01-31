//
//  ASCEditorManagerExtension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31.01.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

extension ASCEditorManager: ASCEditorManagerProtocol {
    // MARK: - Value holder

    private enum Holder {
        static var documentEditorExternalSettings: [AnyHashable: Any] = [
            "asc.de.external.appname": ASCConstants.Name.appNameShort,
            "asc.de.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/document-editor/index.aspx",
            "asc.de.external.page.formats": [
                [
                    "description": "A6",
                    "size": "10.5 x 14.8",
                    "value": [105, 148], // 105 × 148
                ], [
                    "description": "A2",
                    "size": "42 x 59.4",
                    "value": [420, 594], // 420 × 594
                ], [
                    "description": "A1",
                    "size": "59.4 x 84.1",
                    "value": [594, 841], // 594 × 841
                ], [
                    "description": "A0",
                    "size": "84.1 x 118.9",
                    "value": [841, 1189], // 841 × 1189
                ],
            ],
        ]

        static var spreadsheetEditorExternalSettings: [AnyHashable: Any] = {
            let shortCm = NSLocalizedString("cm", comment: "Cut from centimeters")
            return [
                "asc.se.external.appname": ASCConstants.Name.appNameShort,
                "asc.se.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/spreadsheet-editor/index.aspx",
                "asc.se.external.page.formats": [
                    [
                        "width": 105,
                        "height": 148,
                        "display": String(format: NSLocalizedString("A6 (10,5%@ x 14,8%@)", comment: "Format info"), shortCm, shortCm),
                    ], [
                        "width": 420,
                        "height": 594,
                        "display": String(format: NSLocalizedString("A2 (42%@ x 59,4%@)", comment: "Format info"), shortCm, shortCm),
                    ], [
                        "width": 594,
                        "height": 841,
                        "display": String(format: NSLocalizedString("A1 (59,4%@ x 84,1%@)", comment: "Format info"), shortCm, shortCm),
                    ], [
                        "width": 841,
                        "height": 1189,
                        "display": String(format: NSLocalizedString("A0 (84,1%@ x 119,9%@)", comment: "Format info"), shortCm, shortCm),
                    ],
                ],
            ]
        }()

        static var presentationEditorExternalSettings: [AnyHashable: Any] = [
            "asc.pe.external.appname": ASCConstants.Name.appNameShort,
            "asc.pe.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/presentation-editor/index.aspx",
        ]
    }

    // MARK: - Properties

    var documentEditorExternalSettings: [AnyHashable: Any] { return Holder.documentEditorExternalSettings }

    var spreadsheetEditorExternalSettings: [AnyHashable: Any] { return Holder.spreadsheetEditorExternalSettings }

    var presentationEditorExternalSettings: [AnyHashable: Any] { return Holder.presentationEditorExternalSettings }

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
}
