//
//  ASCSpreadsheetEditorExternalSettings.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

final class ASCSpreadsheetEditorExternalSettings: ASCSpreadsheetEditorExternalSettingsProtocol {
    var editorExternalSettings: [AnyHashable: Any] {
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
    }
}
