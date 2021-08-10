//
//  ASCSharingSettingsAccessProviderFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessProviderFactory {
    func get(entity: ASCEntity, isAccessExternal: Bool) -> ASCSharingSettingsAccessProvider {
        if let file = entity as? ASCFile {
            let fileExtension = file.title.fileExtension()
            if fileExtension == "docx" {
                return ASCSharingSettingsAccessDocumentProvider()
            } else if fileExtension == "xlsx" {
                return ASCSharingSettingsAccessTableProvider()
            } else if fileExtension == "pptx" {
                return ASCSharingSettingsAccessPresentationProvider()
            }
        }
        
        return isAccessExternal
            ? ASCSharingSettingsAccessExternalDefaultProvider()
            : ASCSharingSettingsAccessDefaultProvider()
    }
}
