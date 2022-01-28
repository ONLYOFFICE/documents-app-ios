//
//  ASCSharingSettingsAccessProviderFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessProviderFactory {
    typealias FileExtension = String
    typealias ProviderContainer = () -> ASCSharingSettingsAccessProvider

    private let providerContainersByExtension: [FileExtension: ProviderContainer] = [
        "docx":  { ASCSharingSettingsAccessDocumentProvider() },
        "docxf": { ASCSharingSettingsAccessDocumentFormProvider() },
        "xlsx":  { ASCSharingSettingsAccessTableProvider() },
        "pptx":  { ASCSharingSettingsAccessPresentationProvider() },
        "oform": { ASCSharingSettingsAccessOFormProvider() },
    ]
    
    func get(entity: ASCEntity, isAccessExternal: Bool) -> ASCSharingSettingsAccessProvider {
        if let file = entity as? ASCFile,
           let porviderContainer = providerContainersByExtension[file.title.fileExtension()]
        {
            return porviderContainer()
        }
        
        return isAccessExternal
            ? ASCSharingSettingsAccessExternalDefaultProvider()
            : ASCSharingSettingsAccessDefaultProvider()
    }
}
