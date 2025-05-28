//
//  ASCSpreadsheetEditorConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SpreadsheetEditor

final class ASCSpreadsheetEditorConfiguration: ASCSpreadsheetEditorConfigurationProtocol {
    var editorExternalSettings: [AnyHashable: Any] {
        let shortCm = NSLocalizedString("cm", comment: "Cut from centimeters")
        var settings: [AnyHashable: Any] = [
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

        if ASCAppSettings.Feature.allowUserVoice {
            settings["asc.se.external.uservoiceurl"] = "https://onlyoffice.com/"
        }

        return settings
    }

    func localEditor(
        config: SpreadsheetEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> SpreadsheetEditor.EditorConfiguration {
        config
    }

    func cloudEditor(
        config: SpreadsheetEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> SpreadsheetEditor.EditorConfiguration {
        var config = config

        if let file, let folder = file.parent, let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
            let canEdit = onlyofficeProvider.allowEdit(entity: file)
            let canShare = onlyofficeProvider.allowShare(entity: file)
            let canDownload = !file.denyDownload
            let isProjects = file.rootFolderType == .bunch || file.rootFolderType == .projects

            config.supportShare = canEdit && canShare && !isProjects && canDownload && folder.roomType == nil
        }

        return config
    }
}
