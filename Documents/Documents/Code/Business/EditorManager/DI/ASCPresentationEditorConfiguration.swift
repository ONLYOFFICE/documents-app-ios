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
        [
            "asc.pe.external.appname": ASCConstants.Name.appNameShort,
            "asc.pe.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/presentation-editor/index.aspx",
        ]
    }

    func localEditor(config: PresentationEditor.EditorConfiguration) -> PresentationEditor.EditorConfiguration {
        config
    }

    func cloudEditor(config: PresentationEditor.EditorConfiguration) -> PresentationEditor.EditorConfiguration {
        config
    }
}
