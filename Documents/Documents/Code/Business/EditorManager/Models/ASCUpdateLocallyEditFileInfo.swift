//
//  ASCUpdateLocallyEditFileInfo.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct ASCUpdateLocallyEditFileInfo {
    var file: ASCFile?
    var config: OnlyofficeDocumentConfig?
    var openMode: ASCDocumentOpenMode = .view
    var canEdit: Bool = false
}
