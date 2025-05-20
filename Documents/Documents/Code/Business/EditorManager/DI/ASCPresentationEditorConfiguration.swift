//
//  ASCPresentationEditorConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import PresentationEditor

final class ASCPresentationEditorConfiguration: ASCPresentationEditorConfigurationProtocol {
    var editorExternalSettings: [AnyHashable: Any] {
        var settings: [AnyHashable: Any] = [
            "asc.pe.external.appname": ASCConstants.Name.appNameShort,
            "asc.pe.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/presentation-editor/index.aspx",
        ]

        if ASCAppSettings.Feature.allowUserVoice {
            settings["asc.pe.external.uservoiceurl"] = "https://onlyoffice.com/"
        }

        return settings
    }

    func localEditor(
        config: PresentationEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> PresentationEditor.EditorConfiguration {
        config
    }

    func cloudEditor(
        config: PresentationEditor.EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> PresentationEditor.EditorConfiguration {
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
