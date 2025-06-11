//
//  ASCDocumentEditorConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor

final class ASCDocumentEditorConfiguration: ASCDocumentEditorConfigurationProtocol {
    var editorExternalSettings: [AnyHashable: Any] {
        var settings: [AnyHashable: Any] = [
            "asc.de.external.appname": ASCConstants.Name.appNameShort,
            "asc.de.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/document-editor/index.aspx",
            "asc.de.external.uservoiceurl": ASCConstants.Urls.userVoiceUrl,
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

        return settings
    }

    func localEditor(
        config: DocumentEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> DocumentEditor.EditorConfiguration {
        config
    }

    func cloudEditor(
        config: DocumentEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> DocumentEditor.EditorConfiguration {
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
