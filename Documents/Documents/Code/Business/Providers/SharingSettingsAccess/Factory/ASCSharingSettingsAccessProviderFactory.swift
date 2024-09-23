//
//  ASCSharingSettingsAccessProviderFactory.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessProviderFactory {
    typealias FileExtension = String
    typealias ProviderContainer = () -> ASCSharingSettingsAccessProvider

    private let providerContainersByExtension: [FileExtension: ProviderContainer] = [
        ASCConstants.FileExtensions.docx: { ASCSharingSettingsAccessDocumentProvider() },
        ASCConstants.FileExtensions.docxf: { ASCSharingSettingsAccessDocumentFormProvider() },
        ASCConstants.FileExtensions.xlsx: { ASCSharingSettingsAccessTableProvider() },
        ASCConstants.FileExtensions.pptx: { ASCSharingSettingsAccessPresentationProvider() },
        ASCConstants.FileExtensions.oform: { ASCSharingSettingsAccessOFormProvider() },
        ASCConstants.FileExtensions.pdf: { ASCSharingSettingsAccessOFormProvider() },
    ]

    func get(
        entity: ASCEntity,
        isAccessExternal: Bool,
        rightHoldersTableType: RightHoldersTableType? = nil
    ) -> ASCSharingSettingsAccessProvider {
        if let file = entity as? ASCFile,
           let porviderContainer = providerContainersByExtension[file.title.fileExtension()]
        {
            return porviderContainer()
        }

        guard let folder = entity as? ASCFolder, let roomType = folder.roomType else {
            return isAccessExternal
                ? ASCSharingSettingsAccessExternalDefaultProvider()
                : ASCSharingSettingsAccessDefaultProvider()
        }

        return ASCSharingSettingsAccessRoomsProvider(
            roomType: roomType,
            rightHoldersTableType: rightHoldersTableType
        )
    }
}
